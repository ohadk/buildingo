import { NextRequest } from "next/server";

type Method = "GET" | "POST" | "PATCH" | "DELETE";

export async function invoke(
  handler: (req: NextRequest) => Promise<Response>,
  opts: {
    method?: Method;
    path?: string;
    body?: unknown;
    bearer?: string;
    cookie?: string;
  } = {},
) {
  const method = opts.method ?? "GET";
  const path = opts.path ?? "http://localhost/api/test";
  const headers = new Headers();
  if (opts.bearer) headers.set("Authorization", `Bearer ${opts.bearer}`);
  if (opts.cookie) headers.set("Cookie", `dira_session=${opts.cookie}`);
  if (opts.body !== undefined) headers.set("Content-Type", "application/json");

  const req = new NextRequest(path, {
    method,
    headers,
    body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
  });

  const res = await handler(req);
  const text = await res.text();
  const json = text ? JSON.parse(text) : null;
  return { status: res.status, json, headers: res.headers };
}
