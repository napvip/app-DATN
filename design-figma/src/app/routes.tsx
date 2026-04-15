import { createBrowserRouter } from "react-router";
import { Splash } from "./screens/Splash";
import { Onboarding } from "./screens/Onboarding";
import { Login } from "./screens/Login";
import { Register } from "./screens/Register";
import { ForgotPassword } from "./screens/ForgotPassword";
import { MainApp } from "./screens/MainApp";
import { Home } from "./screens/Home";
import { Alerts } from "./screens/Alerts";
import { Insights } from "./screens/Insights";
import { Maintenance } from "./screens/Maintenance";
import { Profile } from "./screens/Profile";
import { HiveDetail } from "./screens/HiveDetail";
import { AddHive } from "./screens/AddHive";
import { ErrorBoundary } from "./components/ErrorBoundary";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Splash,
    errorElement: <ErrorBoundary />,
  },
  {
    path: "/onboarding",
    Component: Onboarding,
    errorElement: <ErrorBoundary />,
  },
  {
    path: "/login",
    Component: Login,
    errorElement: <ErrorBoundary />,
  },
  {
    path: "/register",
    Component: Register,
    errorElement: <ErrorBoundary />,
  },
  {
    path: "/forgot-password",
    Component: ForgotPassword,
    errorElement: <ErrorBoundary />,
  },
  {
    path: "/app",
    Component: MainApp,
    errorElement: <ErrorBoundary />,
    children: [
      { index: true, Component: Home },
      { path: "alerts", Component: Alerts },
      { path: "insights", Component: Insights },
      { path: "maintenance", Component: Maintenance },
      { path: "profile", Component: Profile },
    ],
  },
  {
    path: "/hive/:id",
    Component: HiveDetail,
    errorElement: <ErrorBoundary />,
  },
  {
    path: "/add-hive",
    Component: AddHive,
    errorElement: <ErrorBoundary />,
  },
]);