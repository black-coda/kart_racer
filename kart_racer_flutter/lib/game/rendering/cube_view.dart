import 'package:flutter_scene/scene.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Renders flutter_scene's built-in cube — the M0 feasibility spike (step 5).
/// No asset pipeline involved; geometry and materials are built into the package.
class CubeView extends StatefulWidget {
  const CubeView({super.key});

  @override
  State<CubeView> createState() => _CubeViewState();
}

class _CubeViewState extends State<CubeView> {
  final Scene scene = Scene();
  bool ready = false;

  @override
  void initState() {
    super.initState();
    // Geometry and materials touch the shader bundle, so build them once the
    // engine's static resources are up.
    Scene.initializeStaticResources().then((_) {
      scene.add(
        Node(
          mesh: Mesh(
            CuboidGeometry(vm.Vector3(1, 1, 1)),
            PhysicallyBasedMaterial(),
          ),
        ),
      );
      if (mounted) setState(() => ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SceneView(
        scene,
        camera: PerspectiveCamera(position: vm.Vector3(2, 3, -4)),
      ),
    );
  }
}
