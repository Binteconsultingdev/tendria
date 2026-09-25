import 'package:get/get.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper_getx.dart';
import 'package:tendria/features/plans/data/plans_repository.dart';
import 'package:tendria/features/plans/domain/entities/plan_entities.dart';

/// Listas de planes: descubrir (con filtro por categoría) y los míos.
class PlansController extends GetxController {
  final PlansRepository repository = PlansRepository.instance;

  final RxList<PlanEntity> discover = <PlanEntity>[].obs;
  final RxList<PlanEntity> upcoming = <PlanEntity>[].obs;
  final RxList<PlanEntity> past = <PlanEntity>[].obs;
  final RxnString category = RxnString();

  final RxBool loadingDiscover = false.obs;
  final RxBool loadingMore = false.obs;
  final RxBool loadingMine = false.obs;
  final RxBool discoverError = false.obs;
  final RxBool hasMore = true.obs;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    refreshDiscover();
    refreshMine();
  }

  Future<void> refreshDiscover() async {
    try {
      loadingDiscover.value = true;
      discoverError.value = false;
      _page = 1;
      final result = await repository.discover(category: category.value, page: 1);
      discover.assignAll(result.items);
      hasMore.value = result.hasNext;
    } catch (e) {
      discoverError.value = true;
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      loadingDiscover.value = false;
    }
  }

  Future<void> loadMore() async {
    if (loadingDiscover.value || loadingMore.value || !hasMore.value) return;
    try {
      loadingMore.value = true;
      final result = await repository.discover(category: category.value, page: _page + 1);
      _page++;
      discover.addAll(result.items);
      hasMore.value = result.hasNext;
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      loadingMore.value = false;
    }
  }

  Future<void> refreshMine() async {
    try {
      loadingMine.value = true;
      final results = await Future.wait([repository.myPlans(), repository.myPlans(past: true)]);
      upcoming.assignAll(results[0]);
      past.assignAll(results[1]);
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      loadingMine.value = false;
    }
  }

  void setCategory(String? value) {
    category.value = value;
    refreshDiscover();
  }

  /// Sincroniza un plan actualizado (tras unirse, salir, etc.) en las listas que ya lo muestran.
  void upsert(PlanEntity plan) {
    void replace(RxList<PlanEntity> list) {
      final i = list.indexWhere((p) => p.id == plan.id);
      if (i != -1) list[i] = plan;
    }

    replace(discover);
    replace(upcoming);
    replace(past);
  }

  void remove(int planId) {
    discover.removeWhere((p) => p.id == planId);
    upcoming.removeWhere((p) => p.id == planId);
  }
}
