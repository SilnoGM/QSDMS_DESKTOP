/// 后端统一响应结构。
///
/// `code` 用于前端分支处理，`message` 用于用户或开发者提示，`data` 承载
/// 具体业务数据。
export interface ApiResponse<T> {
  code: string;
  message: string;
  data: T;
}
