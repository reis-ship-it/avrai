/**
 * Generate SQL to import (simplified) NYC borough polygons into Supabase.
 *
 * Input:
 * - tmp/geo/nyc_boroughs.geojson (downloaded from dwillis/nyc-maps)
 *
 * Output:
 * - tmp/geo/import_nyc_boroughs_shapes_v1.sql
 *
 * Why:
 * - We keep the app contract stable (`geo_get_locality_shape_geojson_v1`),
 *   but swap circle-generated shapes for real borough polygons.
 * - We downsample coordinates to keep SQL payload sizes reasonable.
 *
 * Run:
 *   node scripts/geo/generate_nyc_boroughs_import_sql.js
 *
 * Then execute the generated SQL in Supabase (after applying migration 048).
 */

const fs = require("node:fs");
const path = require("node:path");

const PROJECT_ROOT = path.resolve(__dirname, "..", "..");
const inputPath = path.join(PROJECT_ROOT, "tmp", "geo", "nyc_boroughs.geojson");
const outputPath = path.join(
  PROJECT_ROOT,
  "tmp",
  "geo",
  "import_nyc_boroughs_shapes_v1.sql",
);

/** Keep every Nth point in each ring (>= 4 points). */
const DOWNSAMPLE_N = 20;

const BORO_TO_LOCALITY_CODE = {
  Manhattan: "us-nyc-manhattan",
  Brooklyn: "us-nyc-brooklyn",
  Queens: "us-nyc-queens",
  Bronx: "us-nyc-bronx",
  "Staten Island": "us-nyc-staten_island",
};

function downsampleRing(ring) {
  if (!Array.isArray(ring) || ring.length < 4) return ring;
  const kept = [];
  for (let i = 0; i < ring.length; i += DOWNSAMPLE_N) {
    kept.push(ring[i]);
  }
  // Ensure closure
  const first = kept[0];
  const last = kept[kept.length - 1];
  if (first && last && (first[0] !== last[0] || first[1] !== last[1])) {
    kept.push(first);
  }
  // Ensure minimum ring validity
  if (kept.length < 4) return ring;
  return kept;
}

function downsampleGeometry(geom) {
  if (!geom || typeof geom !== "object") return geom;
  if (geom.type === "Polygon") {
    return {
      type: "Polygon",
      coordinates: geom.coordinates.map(downsampleRing),
    };
  }
  if (geom.type === "MultiPolygon") {
    return {
      type: "MultiPolygon",
      coordinates: geom.coordinates.map((poly) => poly.map(downsampleRing)),
    };
  }
  // Unknown type; return as-is
  return geom;
}

function dollarQuote(jsonString) {
  // Avoid collisions: use a rarely-occurring tag.
  return `$geojson$${jsonString}$geojson$`;
}

function main() {
  if (!fs.existsSync(inputPath)) {
    throw new Error(
      `Missing input GeoJSON. Download it first: ${inputPath}\n` +
        `Suggested: curl -L -o ${inputPath} https://raw.githubusercontent.com/dwillis/nyc-maps/master/boroughs.geojson`,
    );
  }

  const raw = fs.readFileSync(inputPath, "utf8");
  const doc = JSON.parse(raw);
  if (doc.type !== "FeatureCollection" || !Array.isArray(doc.features)) {
    throw new Error("Unexpected GeoJSON format (expected FeatureCollection).");
  }

  const statements = [];
  statements.push("-- Generated file: import NYC borough locality shapes");
  statements.push("-- Source: https://raw.githubusercontent.com/dwillis/nyc-maps/master/boroughs.geojson");
  statements.push("-- Note: geometries are downsampled for payload size.");
  statements.push("-- Requires: migration 048 (upsert_geo_locality_shape_geojson_v1)");
  statements.push("");

  for (const f of doc.features) {
    const boroName = f?.properties?.BoroName;
    if (!boroName || typeof boroName !== "string") continue;
    const localityCode = BORO_TO_LOCALITY_CODE[boroName];
    if (!localityCode) continue;

    const geom = downsampleGeometry(f.geometry);
    const geomJson = JSON.stringify(geom);
    const sql = [
      "select public.upsert_geo_locality_shape_geojson_v1(",
      `  '${localityCode}',`,
      `  (${dollarQuote(geomJson)})::jsonb,`,
      `  'dwillis_nyc-maps_downsampled_n${DOWNSAMPLE_N}'`,
      ");",
      "",
    ].join("\n");
    statements.push(sql);
  }

  if (statements.length < 6) {
    throw new Error("Failed to generate statements (no boroughs matched).");
  }

  // Ensure output directory exists (so the script works even after tmp/ is cleaned/quarantined).
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, statements.join("\n"), "utf8");
  // eslint-disable-next-line no-console
  console.log(`Wrote: ${outputPath}`);
}

main();

