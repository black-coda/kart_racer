import 'package:flutter_scene/scene.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// M0 step 6: loads both GLB karts through the flutter_scene asset pipeline
/// and spins them slowly. All flutter_scene imports stay in game/rendering.
class ModelsView extends StatefulWidget {
  const ModelsView({super.key});

  @override
  State<ModelsView> createState() => _ModelsViewState();
}

class _ModelsViewState extends State<ModelsView> {
  final Scene scene = Scene();
  Node? type1;
  Node? type2;
  bool ready = false;
  String? error;

  @override
  void initState() {
    super.initState();
    Scene.initializeStaticResources().then((_) async {
      try {
        type1 = await loadScene('assets/3d/type-1.glb');
        type2 = await loadScene('assets/3d/type-2.glb');
        // Side by side; models sit on Y=0 with their authored scale.
        type1!.position = vm.Vector3(-1.5, 0, 8);
        type2!.position = vm.Vector3(1.5, 0, 8);
        scene.add(type1!);
        scene.add(type2!);
        if (mounted) setState(() => ready = true);
      } catch (e) {
        if (mounted) setState(() => error = '$e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(body: Center(child: Text('Load failed: $error')));
    }
    if (!ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SceneView(
        scene,
        // Default studio environment provides the light (README).
        // camera: OrthographicCamera(
        //   position: vm.Vector3(0, 1.5, -4),
        //   target: vm.Vector3(0, 0.3, 0),
        // ),

        camera: PerspectiveCamera(
          position: vm.Vector3(0, 1.5, 2),
          target: vm.Vector3(0, 0, 8),
        ),

        onTick: (elapsed, deltaSeconds) {
          // Slow spin around Y; rotation setter leaves position/scale alone.
          final angle = elapsed.inMicroseconds / 1e6 * 0.5;
          final q = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), angle);
          type1?.rotation = q;
          type2?.rotation = q;
        },
      ),
    );
  }
}
