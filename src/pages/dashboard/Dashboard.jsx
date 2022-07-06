import React, { useState, useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";

import RoleSelection from "./RoleSelection";
import "./dashboard.css";

const Dashboard = () => {
  const { loading, isAuthenticated, user, roleSelection, xyz } = useSelector((state) => state.auth);
  const roles = user?.role?.split(",");
  const [roleSelectionModal, setRoleSelectionModal] = useState(true);
  const dispatch = useDispatch();

  const roleSelect = (role) => {
    const data = { user };
    data.user.currentRole = role;
    data.roleSelection = false;

    dispatch({
      type: "SELECT_ROLE",
      payload: data,
    });

    sessionStorage.setItem("roleSelection", true);
    sessionStorage.setItem("user", JSON.stringify(data.user));
  };

  const handleChangeRole = () => {
    const data = { user };
    data.roleSelection = true;
    dispatch({
      type: "SELECT_ROLE",
      payload: data,
    });
  };

  useEffect(() => {
    const isSelect = sessionStorage.getItem("roleSelection");
    const data = { user };
    if (roles.length === 1) {
      data.user.currentRole = data.user.role;
      data.roleSelection = false;
    }

    if (!isSelect && roles.length !== 1) {
      data.roleSelection = true;
    }

    // else {
    //   data.roleSelection = true;
    // }

    dispatch({
      type: "SELECT_ROLE",
      payload: data,
    });
  }, []);

  const handleRole = (role) => {
    switch (role) {
      case "ROLE_ADMIN":
        return "Admin";
      case "ROLE_CARE_MANAGER":
        return "Care Manager";
      case "ROLE_CASE_MANAGER":
        return "Case Manager";
      case "ROLE_CARE_GIVER":
        return "Care Giver";
      case "ROLE_CARE_PHYSICIAN":
        return "Care Physician";
      case "ROLE_APPLICATION_ADMIN":
        return "Application Admin";
      default:
        return "User";
    }
  };

  return (
    <>
      {/* {console.log(roles, "=====", roleSelection, roleSelectionModal)} */}

      {roles && roles.length > 1 && roleSelection && (
        <RoleSelection
          handleClick={() => setRoleSelectionModal(!roleSelectionModal)}
          isOpen={roleSelectionModal}
          roleSelect={roleSelect}
          roleList={roles}
        />
      )}

      {user.currentRole && (
        <>
          <div className="row">
            <div className="col-10">
              <h1 className="h3 mb-3">{handleRole(user.currentRole)} Dashboard</h1>
            </div>
            {roles && roles.length > 1 && (
              <div className="col-2 text-end">
                <button type="button" className="btn btn-primary" onClick={handleChangeRole}>
                  Change Role
                </button>
              </div>
            )}
          </div>
          <div className="row">
            <div className="col-12">
              {user.currentRole === "ROLE_ADMIN" ? (
                <div className="card">
                  <div className="card-header">
                    <div className="row">
                      <div className="col-4 p-3">
                        <div className="">
                          <div className="bg-white">
                            <div className="d-flex flex-wrap">
                              <div className="w-50 p-1">
                                <div className="bg-members border hover-shadow bg-new-members" />
                              </div>
                              <div className="w-50 p-1">
                                <div className="bg-members border hover-shadow bg-high-risk-members" />
                              </div>
                              <div className="w-50 p-1">
                                <div className="bg-members border hover-shadow bg-medium-risk-members" />
                              </div>
                              <div className="w-50 p-1">
                                <div className="bg-members border hover-shadow bg-low-risk-members" />
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                      <div className="col-4 p-3">
                        <div className="border">
                          <div className="bg-white dashboard-bg hover-shadow bg-care-plan-funnel" />
                        </div>
                      </div>
                      <div className="col-4 p-3">
                        <div className="border">
                          <div className="bg-white dashboard-bg hover-shadow bg-notifications-opened" />
                        </div>
                      </div>
                      <div className="col-4 p-3">
                        <div className="border">
                          <div className="bg-white dashboard-bg hover-shadow bg-member-milestone" />
                        </div>
                      </div>
                      <div className="col-4 p-3">
                        <div className="border">
                          <div className="bg-white dashboard-bg hover-shadow bg-todays-task" />
                        </div>
                      </div>
                      <div className="col-4 p-3">
                        <div className="border">
                          <div className="bg-white dashboard-bg hover-shadow bg-task-report" />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="card">
                  <div className="card-header">
                    <div className="row">
                      <div className="col-12 p-3">
                        <div className="border">
                          <div className=" bg-coming-soon" />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </>
      )}
    </>
  );
};

export default Dashboard;
