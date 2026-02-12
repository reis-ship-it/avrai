/**
 * Generate a simplified offline-first GeoJSON for NYC borough boundaries.
 *
 * Input:
 * - tmp/geo/nyc_boroughs.geojson (downloaded from dwillis/nyc-maps)
 *
 * Output:
 * - assets/geo/localities/nyc_boroughs_simplified_v1.geojson
 *
 * Run:
 *   node scripts/geo/generate_nyc_boroughs_asset_geojson.js
 */

const fs = require("node:fs");
const path = require("node:path");

const PROJECT_ROOT = path.resolve(__dirname, "..", "..");
const inputPath = path.join(PROJECT_ROOT, "tmp", "geo", "nyc_boroughs.geojson");
const outputPath = path.join(
  PROJECT_ROOT,
  "assets",
  "geo",
  "localities",
  "nyc_boroughs_simplified_v1.geojson",
);

// Keep every Nth point in each ring. Higher = smaller file / faster point-in-poly.
const DOWNSAMPLE_N = 25;

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
  if (kept.length < 4) return ring;
  return kept;
}

function downsampleGeometry(geom) {
  if (!geom || typeof geom !== "object") return geom;
  if (geom.type === "Polygon") {
    return { type: "Polygon", coordinates: geom.coordinates.map(downsampleRing) };
  }
  if (geom.type === "MultiPolygon") {
    return {
      type: "MultiPolygon",
      coordinates: geom.coordinates.map((poly) => poly.map(downsampleRing)),
    };
  }
  return geom;
}

function main() {
  if (!fs.existsSync(inputPath)) {
    throw new Error(
      `Missing input: ${inputPath}\n` +
        `Download it first:\n` +
        `curl -L -o ${inputPath} https://raw.githubusercontent.com/dwillis/nyc-maps/master/boroughs.geojson`,
    );
  }

  const raw = fs.readFileSync(inputPath, "utf8");
  const doc = JSON.parse(raw);
  if (doc.type !== "FeatureCollection" || !Array.isArray(doc.features)) {
    throw new Error("Unexpected GeoJSON format (expected FeatureCollection).");
  }

  const outFeatures = [];
  for (const f of doc.features) {
    const boroName = f?.properties?.BoroName;
    if (!boroName || typeof boroName !== "string") continue;
    const localityCode = BORO_TO_LOCALITY_CODE[boroName];
    if (!localityCode) continue;

    outFeatures.push({
      type: "Feature",
      properties: {
        locality_code: localityCode,
        city_code: "us-nyc",
        display_name: boroName,
        source: `dwillis_nyc-maps_downsampled_n${DOWNSAMPLE_N}`,
      },
      geometry: downsampleGeometry(f.geometry),
    });
  }

  const out = {
    type: "FeatureCollection",
    properties: {
      dataset: "nyc_boroughs_simplified_v1",
      created_by: "scripts/geo/generate_nyc_boroughs_asset_geojson.js",
      downsample_n: DOWNSAMPLE_N,
      source_url:
        "https://raw.githubusercontent.com/dwillis/nyc-maps/master/boroughs.geojson",
    },
    features: outFeatures,
  };

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, JSON.stringify(out), "utf8");
  // eslint-disable-next-line no-console
  console.log(`Wrote: ${outputPath} (features: ${outFeatures.length})`);
}

main();

