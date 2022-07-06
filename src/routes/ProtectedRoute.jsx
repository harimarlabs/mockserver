import React from "react";
import { useSelector } from "react-redux";
import { useLocation, Navigate, Outlet, Route } from "react-router-dom";

const ProtectedRoute = ({ roles = [] }) => {
  const location = useLocation();
  const { loading, isAuthenticated, user } = useSelector((state) => state.auth);
  const userRoles = user?.role?.split(",") || [];

  return (
    <>
      {!loading &&
        (userRoles.find((role) => roles.includes(role)) ? (
          <Outlet />
        ) : isAuthenticated ? (
          <Navigate to="/unauthorized" state={{ from: location }} replace />
        ) : (
          <Navigate to="/login" state={{ from: location }} replace />
        ))}

      {/* <Outlet /> */}
    </>
  );
};
export default ProtectedRoute;
