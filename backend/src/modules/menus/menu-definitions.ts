import type { AuthMenu } from '../auth/models/auth-session.model';

/// 首版桌面端固定入口。
///
/// 菜单展示仍由权限控制；这里仅保存前端路由需要的稳定元数据，不承载业务权限。
export const MENU_DEFINITIONS: readonly AuthMenu[] = [
  {
    key: 'dashboard',
    title: '工作台',
    route: '/',
    icon: 'LayoutDashboard',
    permissionCode: 'menu:dashboard',
    sortOrder: 10,
    children: [],
  },
  {
    key: 'base-data',
    title: '基础数据',
    route: '/base-data',
    icon: 'Database',
    permissionCode: 'menu:base-data',
    sortOrder: 20,
    children: [],
  },
  {
    key: 'system-settings',
    title: '系统设置',
    route: '/settings',
    icon: 'Settings',
    permissionCode: 'menu:settings',
    sortOrder: 30,
    children: [],
  },
];
