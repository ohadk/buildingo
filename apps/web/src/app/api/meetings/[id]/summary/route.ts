import { NextRequest, NextResponse } from "next/server";
import Anthropic from "@anthropic-ai/sdk";
import { PDFDocument, StandardFonts } from "pdf-lib";
import { ApiError, requireRole, withErrorHandling } from "@/lib/auth/session";
import { logAudit } from "@/lib/audit";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { env } from "@/lib/env";

/**
 * POST /api/meetings/:id/summary — closes the meeting, has Claude write
 * a formal recap (agenda + vote outcomes), renders it to PDF, stores it
 * in the "documents" bucket, and posts it to the building bulletin.
 */
export const POST = withErrorHandling(
  async (req: NextRequest, { params }: { params: Promise<{ id: string }> }) => {
    const user = await requireRole(req, "vaad", "super_admin");
    const { id } = await params;
    const db = supabaseAdmin();

    const { data: meeting } = await db
      .from("meetings")
      .select("*, votes(*, vote_ballots(selected_option))")
      .eq("id", id)
      .eq("building_id", user.building_id!)
      .maybeSingle();
    if (!meeting) throw new ApiError(404, "Meeting not found in your building");

    // Tally votes per poll
    const voteResults = (meeting.votes ?? []).map(
      (v: { title: string; options: string[]; vote_ballots: { selected_option: string }[] }) => ({
        title: v.title,
        tally: v.vote_ballots.reduce<Record<string, number>>((acc, b) => {
          acc[b.selected_option] = (acc[b.selected_option] ?? 0) + 1;
          return acc;
        }, {}),
      }),
    );

    const anthropic = new Anthropic({ apiKey: env.anthropicApiKey });
    const response = await anthropic.messages.create({
      model: "claude-sonnet-4-5",
      max_tokens: 2000,
      system:
        "You write formal building assembly summary documents for residents. Plain text only, no markdown syntax. Structure: title, date/location, agenda recap, resolutions with vote tallies, closing note.",
      messages: [
        {
          role: "user",
          content: JSON.stringify({
            title: meeting.title,
            date: meeting.meeting_date,
            location: meeting.location,
            agenda: meeting.agenda,
            voteResults,
          }),
        },
      ],
    });
    const summaryText = response.content
      .filter((b) => b.type === "text")
      .map((b) => b.text)
      .join("\n");

    // Render a simple PDF
    const pdf = await PDFDocument.create();
    const font = await pdf.embedFont(StandardFonts.TimesRoman);
    let page = pdf.addPage([595, 842]); // A4
    const margin = 50;
    let y = 792;
    for (const line of summaryText.split("\n")) {
      // naive wrap at ~90 chars
      const chunks = line.match(/.{1,90}(\s|$)/g) ?? [""];
      for (const chunk of chunks) {
        if (y < margin) {
          page = pdf.addPage([595, 842]);
          y = 792;
        }
        page.drawText(chunk.trim(), { x: margin, y, size: 11, font });
        y -= 16;
      }
    }
    const pdfBytes = await pdf.save();

    const path = `${meeting.building_id}/building/meeting-summary-${meeting.id}.pdf`;
    const { error: uploadError } = await db.storage
      .from("documents")
      .upload(path, Buffer.from(pdfBytes), { contentType: "application/pdf", upsert: true });
    if (uploadError) throw new ApiError(500, uploadError.message);

    await Promise.all([
      db.from("meetings").update({ summary_doc_path: path, is_closed: true }).eq("id", meeting.id),
      db.from("documents").insert({
        building_id: meeting.building_id,
        title: `Meeting summary — ${meeting.title}`,
        file_path: path,
        file_type: "application/pdf",
        uploaded_by: user.id,
      }),
      db.from("announcements").insert({
        building_id: meeting.building_id,
        title: `Summary published: ${meeting.title}`,
        body: "The assembly summary document is now available in the building documents.",
        attachment_path: path,
        created_by: user.id,
      }),
    ]);

    await logAudit({
      buildingId: meeting.building_id,
      actorId: user.id,
      action: "meeting_closed",
      entityType: "meeting",
      entityId: meeting.id,
      details: { title: meeting.title },
    });

    return NextResponse.json({ summaryDocPath: path, summaryText });
  },
);
