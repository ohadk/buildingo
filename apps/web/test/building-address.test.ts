import { describe, expect, it } from "vitest";
import {
  buildingAddressHash,
  canonicalizeBuildingAddress,
  composeStreetAddress,
  isSameBuildingAddress,
  stripStreetPrefix,
} from "@/lib/building-address";

describe("building-address (single source of truth)", () => {
  it("strips Hebrew street prefixes", () => {
    expect(stripStreetPrefix("רח מייזנר")).toBe("מייזנר");
    expect(stripStreetPrefix("רחוב מייזנר 17")).toBe("מייזנר 17");
    expect(composeStreetAddress("רח מייזנר", "17")).toBe("מייזנר 17");
  });

  it("treats רח מייזנר 17 and מייזנר 17 as the same building", () => {
    const a = canonicalizeBuildingAddress({
      city: "פתח תקווה",
      address: "רח מייזנר 17",
      country: "ישראל",
    });
    const b = canonicalizeBuildingAddress({
      city: "פתח תקווה",
      street: "מייזנר",
      houseNumber: "17",
      country: "Israel",
    });
    const c = canonicalizeBuildingAddress({
      city: "פתח תקוה",
      address: "מייזנר 17",
    });
    expect(a.address).toBe("מייזנר 17");
    expect(a.city).toBe("פתח תקווה");
    expect(a.addressHash).toBe(b.addressHash);
    expect(a.addressHash).toBe(c.addressHash);
    expect(
      isSameBuildingAddress(
        { city: a.city, address: a.address, country: a.country },
        { city: b.city, address: b.address, country: b.country },
      ),
    ).toBe(true);
  });

  it("hashes are stable for the Meizner test building", () => {
    const hash = buildingAddressHash({
      city: "פתח תקווה",
      address: "מייזנר 17",
      country: "ישראל",
    });
    expect(hash).toMatch(/^[a-f0-9]{32}$/);
    expect(
      buildingAddressHash({
        city: "פתח תקווה",
        address: "רח מייזנר 17",
        country: "IL",
      }),
    ).toBe(hash);
  });
});
