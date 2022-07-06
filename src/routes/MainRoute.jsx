import { lazy } from "react";

const Dashboard = lazy(() => import("../pages/dashboard/Dashboard"));
const Home = lazy(() => import("../pages/home/Home"));
const RiskAnalysis = lazy(() => import("../pages/riskanalysis/RiskAnalysis"));
const Profile = lazy(() => import("../pages/Profile"));
const Products = lazy(() => import("../pages/products/Products"));
const Product = lazy(() => import("../pages/products/Product"));
const ProductAdd = lazy(() => import("../pages/products/ProductAdd"));
const AdminDashboard = lazy(() => import("../pages/admin/AdminDashboard"));
const NotFound = lazy(() => import("../pages/NotFound"));
const Users = lazy(() => import("../pages/user/Users"));
const Notifications = lazy(() => import("../pages/notification/Notifications"));
const Notification = lazy(() => import("../pages/notification/Notification"));

const PatientEnrollmentList = lazy(() =>
  import("../pages/patientEnrollment/PatientEnrollmentList"),
);

const CarePlan = lazy(() => import("../pages/carePlanDraft/CarePlan"));
const RiskScoring = lazy(() => import("../pages/riskScoring/RiskScoring"));

const ROLES = {
  ROLE_ADMIN: "ROLE_ADMIN",
  ROLE_CARE_MANAGER: "ROLE_CARE_MANAGER",
  ROLE_CASE_MANAGER: "ROLE_CASE_MANAGER",
  ROLE_CARE_GIVER: "ROLE_CARE_GIVER",
  ROLE_CARE_PHYSICIAN: "ROLE_CARE_PHYSICIAN",
  ROLE_APPLICATION_ADMIN: "ROLE_APPLICATION_ADMIN",
};

const routes = [
  {
    path: "/",
    element: <Home />,
    roles: [
      ROLES.ROLE_ADMIN,
      ROLES.ROLE_CARE_MANAGER,
      ROLES.ROLE_CASE_MANAGER,
      ROLES.ROLE_CARE_GIVER,
      ROLES.ROLE_CARE_PHYSICIAN,
      ROLES.ROLE_APPLICATION_ADMIN,
    ],
  },
  {
    path: "dashboard",
    element: <Dashboard />,
    roles: [
      ROLES.ROLE_ADMIN,
      ROLES.ROLE_CARE_MANAGER,
      ROLES.ROLE_CASE_MANAGER,
      ROLES.ROLE_CARE_GIVER,
      ROLES.ROLE_CARE_PHYSICIAN,
      ROLES.ROLE_APPLICATION_ADMIN,
    ],
  },
  {
    path: "riskanalysis",
    element: <RiskAnalysis />,
    roles: [
      ROLES.ROLE_ADMIN,
      ROLES.ROLE_CARE_MANAGER,
      ROLES.ROLE_CASE_MANAGER,
      ROLES.ROLE_CARE_GIVER,
      ROLES.ROLE_CARE_PHYSICIAN,
      ROLES.ROLE_APPLICATION_ADMIN,
    ],
  },
  {
    path: "products",
    element: <Products />,
    roles: [
      ROLES.ROLE_ADMIN,
      ROLES.ROLE_CARE_MANAGER,
      ROLES.ROLE_CASE_MANAGER,
      ROLES.ROLE_CARE_GIVER,
      ROLES.ROLE_CARE_PHYSICIAN,
      ROLES.ROLE_APPLICATION_ADMIN,
    ],
  },
  {
    path: "product",
    element: <Product />,
    roles: [
      ROLES.ROLE_ADMIN,
      ROLES.ROLE_CARE_MANAGER,
      ROLES.ROLE_CASE_MANAGER,
      ROLES.ROLE_CARE_GIVER,
      ROLES.ROLE_CARE_PHYSICIAN,
      ROLES.ROLE_APPLICATION_ADMIN,
    ],
  },
  {
    path: "product-add",
    element: <ProductAdd />,
    roles: [
      ROLES.ROLE_ADMIN,
      ROLES.ROLE_CARE_MANAGER,
      ROLES.ROLE_CASE_MANAGER,
      ROLES.ROLE_CARE_GIVER,
      ROLES.ROLE_CARE_PHYSICIAN,
      ROLES.ROLE_APPLICATION_ADMIN,
    ],
  },
  {
    path: "profile",
    element: <Profile />,
    roles: [
      ROLES.ROLE_ADMIN,
      ROLES.ROLE_CARE_MANAGER,
      ROLES.ROLE_CASE_MANAGER,
      ROLES.ROLE_CARE_GIVER,
      ROLES.ROLE_CARE_PHYSICIAN,
      ROLES.ROLE_APPLICATION_ADMIN,
    ],
  },
  {
    path: "patient-enrollment",
    element: <PatientEnrollmentList />,
    roles: [
      ROLES.ROLE_ADMIN,
      ROLES.ROLE_CARE_MANAGER,
      ROLES.ROLE_CASE_MANAGER,
      ROLES.ROLE_CARE_GIVER,
      ROLES.ROLE_CARE_PHYSICIAN,
      ROLES.ROLE_APPLICATION_ADMIN,
    ],
  },
  // {
  //   path: "patient-enrollment-add",
  //   element: <PatientEnrollmentUpdate />,
  //   roles: [ROLES.ROLE_ADMIN,ROLES.ROLE_CARE_MANAGER, ROLES.ROLE_CASE_MANAGER],
  // },
  // {
  //   path: "patient-enrollment-view",
  //   element: <PatientEnrollmentView />,
  //   roles: [ROLES.ROLE_ADMIN,ROLES.ROLE_CARE_MANAGER, ROLES.ROLE_CASE_MANAGER],
  // },
  {
    path: "care-plan",
    element: <CarePlan />,
    roles: [
      ROLES.ROLE_ADMIN,
      ROLES.ROLE_CARE_MANAGER,
      ROLES.ROLE_CASE_MANAGER,
      ROLES.ROLE_CARE_GIVER,
      ROLES.ROLE_CARE_PHYSICIAN,
      ROLES.ROLE_APPLICATION_ADMIN,
    ],
  },
  {
    path: "risk-scoring",
    element: <RiskScoring />,
    roles: [
      ROLES.ROLE_ADMIN,
      ROLES.ROLE_CARE_MANAGER,
      ROLES.ROLE_CASE_MANAGER,
      ROLES.ROLE_CARE_GIVER,
      ROLES.ROLE_CARE_PHYSICIAN,
      ROLES.ROLE_APPLICATION_ADMIN,
    ],
  },
  {
    path: "users",
    element: <Users />,
    roles: [
      ROLES.ROLE_ADMIN,
      ROLES.ROLE_CARE_MANAGER,
      ROLES.ROLE_CASE_MANAGER,
      ROLES.ROLE_CARE_GIVER,
      ROLES.ROLE_CARE_PHYSICIAN,
      ROLES.ROLE_APPLICATION_ADMIN,
    ],
  },
  {
    path: "notifications",
    element: <Notifications />,
    roles: [
      ROLES.ROLE_ADMIN,
      ROLES.ROLE_CARE_MANAGER,
      ROLES.ROLE_CASE_MANAGER,
      ROLES.ROLE_CARE_GIVER,
      ROLES.ROLE_CARE_PHYSICIAN,
      ROLES.ROLE_APPLICATION_ADMIN,
    ],
  },
  {
    path: "notification-detail/:id",
    element: <Notification />,
    roles: [
      ROLES.ROLE_ADMIN,
      ROLES.ROLE_CARE_MANAGER,
      ROLES.ROLE_CASE_MANAGER,
      ROLES.ROLE_CARE_GIVER,
      ROLES.ROLE_CARE_PHYSICIAN,
      ROLES.ROLE_APPLICATION_ADMIN,
    ],
  },

  {
    path: "*",
    element: <NotFound />,
    // roles: []
  },
];

export default routes;
