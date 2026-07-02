# QSDMS Desktop Frontend

`frontend/` 是 QSDMS 桌面端前端工作目录，技术栈为 `Flutter Desktop + GetX`。

## 技术栈

- `Flutter Desktop`
- `Dart`
- `GetX`
- `dio`
- `json_serializable`
- `freezed`

## 目录结构

```text
lib/
  app/
    bindings/
    routes/
    theme/
  modules/
    home/
  shared/
    services/
```

- `app/`：应用启动、路由、主题和全局依赖注入。
- `modules/`：业务模块页面、Controller 和 Binding。
- `shared/`：跨模块复用的服务、仓储、模型和工具。

## 常用命令

```bash
flutter pub get
flutter test
flutter analyze
flutter run -d macos
```

## 约束

- 用户可见文案默认使用中文。
- 路由名称、API 路径、DTO 字段名、变量名等技术资产使用英文。
- 页面不直接写复杂业务逻辑，业务编排放入 `GetxController`。
- API 调用统一下沉到 `Service` 或 `Repository`。
- 不提交真实 `.env`，只维护 `.env.example`。
