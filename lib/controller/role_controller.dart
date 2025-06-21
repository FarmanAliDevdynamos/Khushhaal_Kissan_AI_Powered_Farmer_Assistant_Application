import 'package:get/get.dart';

class RoleController extends GetxController {
  var selectedRole = "".obs;

  void setRole(String role) {
    selectedRole.value = role;
  }
}
