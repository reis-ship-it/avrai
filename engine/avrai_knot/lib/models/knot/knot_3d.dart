// Knot 3D Model
//
// Represents a 3D knot representation for visualization and export
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 1: 3D Knot Visualization and Conversion

import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// 3D knot representation with 3D coordinates
///
/// Converts braid data to 3D space coordinates for visualization
class Knot3D {
  /// 3D coordinates of the knot curve
  /// Each Vector3 represents a point along the knot
  final List<Vector3> coordinates;

  /// Crossing information in 3D space
  /// Each crossing has position and over/under information
  final List<Crossing3D> crossings;

  /// Knot invariants (from PersonalityKnot)
  final KnotInvariants invariants;

  /// Agent ID associated with this knot
  final String agentId;

  Knot3D({
    required this.coordinates,
    required this.crossings,
    required this.invariants,
    required this.agentId,
  });

  /// Create 3D knot from braid data
  ///
  /// **Algorithm:**
  /// - Parse braid sequence: [strands, crossing1_strand, crossing1_over, ...]
  /// - Generate 3D curve using parametric equations
  /// - Map braid crossings to 3D crossings
  factory Knot3D.fromBraidData({
    required List<double> braidData,
    required KnotInvariants invariants,
    required String agentId,
  }) {
    if (braidData.isEmpty) {
      throw ArgumentError('Braid data cannot be empty');
    }

    final numStrands = braidData[0].toInt();
    if (numStrands < 2) {
      throw ArgumentError('Braid must have at least 2 strands');
    }

    // Parse crossings from braid data
    final crossings = <Crossing3D>[];
    final crossingPositions = <int, List<double>>{}; // strand -> [positions]

    int i = 1;
    int crossingIndex = 0;
    while (i < braidData.length) {
      if (i + 1 >= braidData.length) break;

      final strand = braidData[i].toInt();
      final isOver = braidData[i + 1] > 0.5;

      // Store crossing position (will be converted to 3D later)
      if (!crossingPositions.containsKey(strand)) {
        crossingPositions[strand] = [];
      }
      crossingPositions[strand]!.add(crossingIndex.toDouble());

      crossings.add(
        Crossing3D(
          index: crossingIndex,
          strand: strand,
          isOver: isOver,
          position:
              Vector3.zero(), // Will be calculated during coordinate generation
        ),
      );

      i += 2;
      crossingIndex++;
    }

    // Generate 3D coordinates using torus knot parameterization
    // Adjust parameters based on knot invariants
    final coordinates = _generate3DCoordinates(
      numStrands: numStrands,
      crossingNumber: invariants.crossingNumber,
      writhe: invariants.writhe,
      crossings: crossings,
    );

    // Update crossing positions with actual 3D coordinates
    final updatedCrossings = _updateCrossingPositions(
      crossings: crossings,
      coordinates: coordinates,
      crossingPositions: crossingPositions,
    );

    return Knot3D(
      coordinates: coordinates,
      crossings: updatedCrossings,
      invariants: invariants,
      agentId: agentId,
    );
  }

  /// Generate 3D coordinates using torus knot parameterization
  ///
  /// Formula: x = (R + r*cos(n*t))*cos(m*t)
  ///          y = (R + r*cos(n*t))*sin(m*t)
  ///          z = r*sin(n*t)
  static List<Vector3> _generate3DCoordinates({
    required int numStrands,
    required int crossingNumber,
    required int writhe,
    required List<Crossing3D> crossings,
  }) {
    final coordinates = <Vector3>[];

    // Torus knot parameters
    // n and m determine the knot type (e.g., trefoil: n=2, m=3)
    final n = (crossingNumber / 2).ceil().clamp(2, 10);
    final m = crossingNumber.clamp(3, 15);

    // Torus parameters
    final R = 2.0; // Major radius
    final r = 0.5; // Minor radius (adjusted by complexity)

    // Number of points along the curve
    final numPoints = (crossingNumber * 20).clamp(100, 1000);

    for (int i = 0; i < numPoints; i++) {
      final t = (i / numPoints) * 2 * 3.14159; // Parameter from 0 to 2π

      // Torus knot parameterization
      final x =
          (R +
              r *
                  (1.0 + 0.2 * writhe.sign) *
                  (writhe.abs() / 10.0).clamp(0.0, 1.0) *
                  math.cos(n * t)) *
          math.cos(m * t);
      final y =
          (R +
              r *
                  (1.0 + 0.2 * writhe.sign) *
                  (writhe.abs() / 10.0).clamp(0.0, 1.0) *
                  math.cos(n * t)) *
          math.sin(m * t);
      final z =
          r *
          (1.0 + 0.2 * writhe.sign) *
          (writhe.abs() / 10.0).clamp(0.0, 1.0) *
          math.sin(n * t);

      coordinates.add(Vector3(x, y, z));
    }

    return coordinates;
  }

  /// Update crossing positions with actual 3D coordinates
  static List<Crossing3D> _updateCrossingPositions({
    required List<Crossing3D> crossings,
    required List<Vector3> coordinates,
    required Map<int, List<double>> crossingPositions,
  }) {
    final updated = <Crossing3D>[];

    for (final crossing in crossings) {
      // Find approximate position based on crossing index
      final positionIndex =
          ((crossing.index / crossings.length) * coordinates.length)
              .round()
              .clamp(0, coordinates.length - 1);

      updated.add(
        Crossing3D(
          index: crossing.index,
          strand: crossing.strand,
          isOver: crossing.isOver,
          position: coordinates[positionIndex],
        ),
      );
    }

    return updated;
  }

  /// Get bounding box of the knot
  ({Vector3 min, Vector3 max}) get boundingBox {
    if (coordinates.isEmpty) {
      return (min: Vector3.zero(), max: Vector3.zero());
    }

    var minX = coordinates[0].x;
    var minY = coordinates[0].y;
    var minZ = coordinates[0].z;
    var maxX = coordinates[0].x;
    var maxY = coordinates[0].y;
    var maxZ = coordinates[0].z;

    for (final coord in coordinates) {
      minX = minX < coord.x ? minX : coord.x;
      minY = minY < coord.y ? minY : coord.y;
      minZ = minZ < coord.z ? minZ : coord.z;
      maxX = maxX > coord.x ? maxX : coord.x;
      maxY = maxY > coord.y ? maxY : coord.y;
      maxZ = maxZ > coord.z ? maxZ : coord.z;
    }

    return (min: Vector3(minX, minY, minZ), max: Vector3(maxX, maxY, maxZ));
  }

  /// Get center point of the knot
  Vector3 get center {
    final bbox = boundingBox;
    return Vector3(
      (bbox.min.x + bbox.max.x) / 2,
      (bbox.min.y + bbox.max.y) / 2,
      (bbox.min.z + bbox.max.z) / 2,
    );
  }
}

/// 3D crossing information
class Crossing3D {
  /// Index of the crossing
  final int index;

  /// Strand index involved in crossing
  final int strand;

  /// Whether this is an over-crossing (true) or under-crossing (false)
  final bool isOver;

  /// 3D position of the crossing
  final Vector3 position;

  Crossing3D({
    required this.index,
    required this.strand,
    required this.isOver,
    required this.position,
  });
}

/// 3D mesh representation of a knot
///
/// Contains vertices, faces, and normals for 3D rendering
class Knot3DMesh {
  /// Vertices of the mesh (3D points)
  final List<Vector3> vertices;

  /// Faces (triangles) of the mesh
  /// Each face is represented by 3 vertex indices
  final List<Face3D> faces;

  /// Normals for each vertex (for lighting)
  final List<Vector3> normals;

  /// Texture coordinates (optional, for future use)
  final List<Vector2>? textureCoords;

  Knot3DMesh({
    required this.vertices,
    required this.faces,
    required this.normals,
    this.textureCoords,
  });

  /// Generate mesh from 3D knot coordinates
  ///
  /// Creates a tube-like mesh around the knot curve
  factory Knot3DMesh.generateMesh({
    required Knot3D knot3d,
    double tubeRadius = 0.1,
    int tubeSegments = 8,
  }) {
    final vertices = <Vector3>[];
    final faces = <Face3D>[];
    final normals = <Vector3>[];

    if (knot3d.coordinates.length < 2) {
      return Knot3DMesh(vertices: vertices, faces: faces, normals: normals);
    }

    // Generate tube around the curve
    for (int i = 0; i < knot3d.coordinates.length; i++) {
      final current = knot3d.coordinates[i];
      final next = knot3d.coordinates[(i + 1) % knot3d.coordinates.length];

      // Calculate tangent (direction along curve)
      final tangent = (next - current).normalized();

      // Calculate normal and binormal for tube cross-section
      final up = Vector3(0, 0, 1);
      var normal = tangent.cross(up).normalized();
      if (normal.length < 0.1) {
        // If tangent is parallel to up, use different reference
        final right = Vector3(1, 0, 0);
        normal = tangent.cross(right).normalized();
      }
      final binormal = tangent.cross(normal).normalized();

      // Generate tube cross-section
      for (int j = 0; j < tubeSegments; j++) {
        final angle = (j / tubeSegments) * 2 * math.pi;
        final offset =
            normal * (math.cos(angle) * tubeRadius) +
            binormal * (math.sin(angle) * tubeRadius);
        vertices.add(current + offset);

        // Calculate normal for lighting
        normals.add(offset.normalized());
      }
    }

    // Generate faces (connect adjacent cross-sections)
    for (int i = 0; i < knot3d.coordinates.length - 1; i++) {
      for (int j = 0; j < tubeSegments; j++) {
        final current = i * tubeSegments + j;
        final next = i * tubeSegments + ((j + 1) % tubeSegments);
        final nextRing = (i + 1) * tubeSegments + j;
        final nextRingNext = (i + 1) * tubeSegments + ((j + 1) % tubeSegments);

        // Create two triangles per quad
        faces.add(Face3D(v0: current, v1: next, v2: nextRing));
        faces.add(Face3D(v0: next, v1: nextRingNext, v2: nextRing));
      }
    }

    return Knot3DMesh(vertices: vertices, faces: faces, normals: normals);
  }

  /// Get number of vertices
  int get vertexCount => vertices.length;

  /// Get number of faces
  int get faceCount => faces.length;
}

/// Face (triangle) in 3D mesh
class Face3D {
  /// Vertex indices (0, 1, 2)
  final int v0;
  final int v1;
  final int v2;

  Face3D({required this.v0, required this.v1, required this.v2});

  /// Get all vertex indices
  List<int> get indices => [v0, v1, v2];
}

/// 3D export functionality for various formats
class Knot3DExport {
  /// Export mesh to OBJ format
  ///
  /// OBJ is a text-based format widely supported by 3D software
  static String toOBJ(Knot3DMesh mesh, {String? objectName}) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('# OBJ file generated from Personality Knot');
    if (objectName != null) {
      buffer.writeln('o $objectName');
    }

    // Vertices
    for (final vertex in mesh.vertices) {
      buffer.writeln('v ${vertex.x} ${vertex.y} ${vertex.z}');
    }

    // Normals
    for (final normal in mesh.normals) {
      buffer.writeln('vn ${normal.x} ${normal.y} ${normal.z}');
    }

    // Faces (using vertex indices and normals)
    for (final face in mesh.faces) {
      // OBJ uses 1-based indexing
      buffer.writeln(
        'f ${face.v0 + 1}//${face.v0 + 1} '
        '${face.v1 + 1}//${face.v1 + 1} '
        '${face.v2 + 1}//${face.v2 + 1}',
      );
    }

    return buffer.toString();
  }

  /// Export mesh to STL format (ASCII)
  ///
  /// STL is commonly used for 3D printing
  static String toSTL(Knot3DMesh mesh, {String? solidName}) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('solid ${solidName ?? "knot"}');

    // Faces (STL uses triangles with normals)
    for (final face in mesh.faces) {
      final v0 = mesh.vertices[face.v0];
      final v1 = mesh.vertices[face.v1];
      final v2 = mesh.vertices[face.v2];

      // Calculate face normal
      final edge1 = v1 - v0;
      final edge2 = v2 - v0;
      final normal = edge1.cross(edge2).normalized();

      buffer.writeln('  facet normal ${normal.x} ${normal.y} ${normal.z}');
      buffer.writeln('    outer loop');
      buffer.writeln('      vertex ${v0.x} ${v0.y} ${v0.z}');
      buffer.writeln('      vertex ${v1.x} ${v1.y} ${v1.z}');
      buffer.writeln('      vertex ${v2.x} ${v2.y} ${v2.z}');
      buffer.writeln('    endloop');
      buffer.writeln('  endfacet');
    }

    buffer.writeln('endsolid ${solidName ?? "knot"}');

    return buffer.toString();
  }

  /// Export mesh to glTF format (JSON)
  ///
  /// glTF is used for web, AR, and VR applications
  static Map<String, dynamic> toGLTF(Knot3DMesh mesh, {String? name}) {
    // Convert vertices to flat array
    final positions = <double>[];
    for (final vertex in mesh.vertices) {
      positions.addAll([vertex.x, vertex.y, vertex.z]);
    }

    // Convert normals to flat array
    final normals = <double>[];
    for (final normal in mesh.normals) {
      normals.addAll([normal.x, normal.y, normal.z]);
    }

    // Convert faces to indices
    final indices = <int>[];
    for (final face in mesh.faces) {
      indices.addAll([face.v0, face.v1, face.v2]);
    }

    return {
      'asset': {'version': '2.0', 'generator': 'AVRAI Knot 3D Export'},
      'scene': 0,
      'scenes': [
        {
          'nodes': [0],
        },
      ],
      'nodes': [
        {'mesh': 0, 'name': name ?? 'knot'},
      ],
      'meshes': [
        {
          'primitives': [
            {
              'attributes': {'POSITION': 0, 'NORMAL': 1},
              'indices': 2,
            },
          ],
        },
      ],
      'accessors': [
        {
          'bufferView': 0,
          'componentType': 5126, // FLOAT
          'count': mesh.vertices.length,
          'type': 'VEC3',
          'max': [
            mesh.vertices.map((v) => v.x).reduce((a, b) => a > b ? a : b),
            mesh.vertices.map((v) => v.y).reduce((a, b) => a > b ? a : b),
            mesh.vertices.map((v) => v.z).reduce((a, b) => a > b ? a : b),
          ],
          'min': [
            mesh.vertices.map((v) => v.x).reduce((a, b) => a < b ? a : b),
            mesh.vertices.map((v) => v.y).reduce((a, b) => a < b ? a : b),
            mesh.vertices.map((v) => v.z).reduce((a, b) => a < b ? a : b),
          ],
        },
        {
          'bufferView': 1,
          'componentType': 5126, // FLOAT
          'count': mesh.normals.length,
          'type': 'VEC3',
        },
        {
          'bufferView': 2,
          'componentType': 5123, // UNSIGNED_SHORT
          'count': indices.length,
          'type': 'SCALAR',
        },
      ],
      'bufferViews': [
        {
          'buffer': 0,
          'byteOffset': 0,
          'byteLength': positions.length * 4, // 4 bytes per float
        },
        {
          'buffer': 0,
          'byteOffset': positions.length * 4,
          'byteLength': normals.length * 4,
        },
        {
          'buffer': 0,
          'byteOffset': (positions.length + normals.length) * 4,
          'byteLength': indices.length * 2, // 2 bytes per unsigned short
        },
      ],
      'buffers': [
        {
          'byteLength':
              (positions.length + normals.length) * 4 + indices.length * 2,
          'uri':
              'data:application/octet-stream;base64,', // Would need base64 encoding
        },
      ],
    };
  }
}
