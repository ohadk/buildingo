/**
 * Minimal in-memory Supabase query builder for API route tests.
 * Supports the chain shapes used by auth, onboarding, and announcements.
 */

type Row = Record<string, unknown>;
type Tables = Record<string, Row[]>;

function clone<T>(v: T): T {
  return structuredClone(v);
}

function uuid() {
  return crypto.randomUUID();
}

function matchFilter(row: Row, column: string, op: string, value: unknown): boolean {
  const left = row[column];
  if (op === "eq") return left === value;
  if (op === "gt") return String(left ?? "") > String(value ?? "");
  if (op === "gte") return String(left ?? "") >= String(value ?? "");
  if (op === "lt") return String(left ?? "") < String(value ?? "");
  if (op === "lte") return String(left ?? "") <= String(value ?? "");
  if (op === "in") return Array.isArray(value) && value.includes(left);
  return true;
}

type Filter = { column: string; op: string; value: unknown };

class QueryBuilder implements PromiseLike<{ data: unknown; error: null | { message: string } }> {
  private filters: Filter[] = [];
  private mutate: "insert" | "update" | "none" = "none";
  private payload: Row | Row[] | null = null;
  private want: "many" | "single" | "maybe" = "many";
  private orderBy: { column: string; ascending: boolean } | null = null;
  private limitCount: number | null = null;
  private selectClause = "*";

  constructor(
    private readonly tables: Tables,
    private readonly table: string,
  ) {}

  select(clause = "*") {
    this.selectClause = clause;
    return this;
  }

  insert(row: Row | Row[]) {
    this.mutate = "insert";
    this.payload = row;
    return this;
  }

  update(patch: Row) {
    this.mutate = "update";
    this.payload = patch;
    return this;
  }

  eq(column: string, value: unknown) {
    this.filters.push({ column, op: "eq", value });
    return this;
  }

  gt(column: string, value: unknown) {
    this.filters.push({ column, op: "gt", value });
    return this;
  }

  gte(column: string, value: unknown) {
    this.filters.push({ column, op: "gte", value });
    return this;
  }

  lt(column: string, value: unknown) {
    this.filters.push({ column, op: "lt", value });
    return this;
  }

  lte(column: string, value: unknown) {
    this.filters.push({ column, op: "lte", value });
    return this;
  }

  in(column: string, value: unknown[]) {
    this.filters.push({ column, op: "in", value });
    return this;
  }

  order(column: string, opts?: { ascending?: boolean }) {
    this.orderBy = { column, ascending: opts?.ascending ?? true };
    return this;
  }

  limit(n: number) {
    this.limitCount = n;
    return this;
  }

  single() {
    this.want = "single";
    return this;
  }

  maybeSingle() {
    this.want = "maybe";
    return this;
  }

  private applySelect(row: Row): Row {
    const out = clone(row);
    if (this.selectClause.includes("buildings!")) {
      const buildingId = out.building_id as string | null;
      const building = buildingId
        ? this.tables.buildings?.find((b) => b.id === buildingId)
        : null;
      out.buildings = building
        ? {
            is_active: building.is_active,
            plan_status: building.plan_status,
            trial_ends_at: building.trial_ends_at,
          }
        : null;
    }
    return out;
  }

  private run(): { data: unknown; error: null | { message: string } } {
    if (!this.tables[this.table]) this.tables[this.table] = [];

    if (this.mutate === "insert") {
      const rows = Array.isArray(this.payload) ? this.payload : [this.payload!];
      const inserted = rows.map((r) => {
        const defaults =
          this.table === "users"
            ? {
                full_name: "",
                num_occupants: 1,
                lease_contract_path: null,
                onboarded_at: null,
                is_active: true,
                building_id: null,
                apartment_id: null,
                role: "tenant",
              }
            : {};
        const row = {
          ...defaults,
          id: (r.id as string) ?? uuid(),
          created_at: new Date().toISOString(),
          ...r,
        };
        this.tables[this.table].push(row);
        return this.applySelect(row);
      });
      if (this.want === "single" || this.want === "maybe") {
        return { data: inserted[0] ?? null, error: null };
      }
      return { data: inserted, error: null };
    }

    let rows = this.tables[this.table].filter((row) =>
      this.filters.every((f) => matchFilter(row, f.column, f.op, f.value)),
    );

    if (this.mutate === "update") {
      const patch = this.payload as Row;
      rows = rows.map((row) => {
        Object.assign(row, patch);
        return row;
      });
    }

    if (this.orderBy) {
      const { column, ascending } = this.orderBy;
      rows = [...rows].sort((a, b) => {
        const av = String(a[column] ?? "");
        const bv = String(b[column] ?? "");
        return ascending ? av.localeCompare(bv) : bv.localeCompare(av);
      });
    }

    if (this.limitCount != null) rows = rows.slice(0, this.limitCount);

    const selected = rows.map((r) => this.applySelect(r));

    if (this.want === "single") {
      if (selected.length !== 1) {
        return { data: null, error: { message: `Expected 1 row, got ${selected.length}` } };
      }
      return { data: selected[0], error: null };
    }
    if (this.want === "maybe") {
      return { data: selected[0] ?? null, error: null };
    }
    return { data: selected, error: null };
  }

  then<TResult1 = { data: unknown; error: null | { message: string } }, TResult2 = never>(
    onfulfilled?:
      | ((value: { data: unknown; error: null | { message: string } }) => TResult1 | PromiseLike<TResult1>)
      | null,
    onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null,
  ) {
    return Promise.resolve(this.run()).then(onfulfilled, onrejected);
  }
}

function emptyTables(): Tables {
  return {
    users: [],
    buildings: [],
    apartments: [],
    invitations: [],
    super_admins: [],
    announcements: [],
    audit_logs: [],
    tenancies: [],
  };
}

class MemoryDb {
  private tables: Tables = emptyTables();

  reset() {
    this.tables = emptyTables();
  }

  seed<T extends Row>(table: string, rows: T[]): T[] {
    if (!this.tables[table]) this.tables[table] = [];
    const withIds = rows.map((r) => ({
      id: (r.id as string) ?? uuid(),
      created_at: (r.created_at as string) ?? new Date().toISOString(),
      ...r,
    }));
    this.tables[table].push(...withIds);
    return withIds as T[];
  }

  all(table: string): Row[] {
    return clone(this.tables[table] ?? []);
  }

  client() {
    return {
      from: (table: string) => new QueryBuilder(this.tables, table),
    };
  }
}

export const memoryDb = new MemoryDb();
