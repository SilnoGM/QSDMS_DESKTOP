import 'package:get/get.dart';

/// 首页业务入口描述。
///
/// 该模型只服务于首页模块入口展示，不承载后端业务实体含义。
class HomeModule {
  const HomeModule({required this.title, required this.description});

  final String title;
  final String description;
}

/// 首页状态控制器。
///
/// Controller 负责页面状态编排；真实业务规则和服务端数据读写后续应下沉到
/// Service / Repository 层，避免页面状态直接变成业务规则实现。
class HomeController extends GetxController {
  final workspaceTitle = '订单处理工作台'.obs;

  final modules = const <HomeModule>[
    HomeModule(title: '订单管理', description: '处理订单、筛选异常、跟进状态'),
    HomeModule(title: '供应商管理', description: '维护供应商资料、账期与协作信息'),
    HomeModule(title: '产品资料', description: '管理产品档案、规格与业务属性'),
    HomeModule(title: '仓储发运', description: '跟踪库存、出入库与发运节点'),
  ].obs;
}
