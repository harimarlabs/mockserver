import React, { useEffect, useState } from "react";
import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";

const RoleSelection = ({ isOpen, handleClick, roleSelect, roleList }) => {
  const listRole = [
    {
      name: "Admin Office",
      icn: "bi bi-shield-lock-fill fs-1",
      val: "ROLE_ADMIN",
    },
    {
      name: "Care Manager",
      icn: "bi bi-person-badge fs-1",
      val: "ROLE_CARE_MANAGER",
    },
    {
      name: "Case Manager",
      icn: "bi bi-person-workspace fs-1",
      val: "ROLE_CASE_MANAGER",
    },
    {
      name: "Care Giver",
      icn: "bi bi-person-hearts fs-1",
      val: "ROLE_CARE_GIVER",
    },
    {
      name: "Primary Care Physician",
      icn: "bi bi-bandaid-fill fs-1",
      val: "ROLE_CARE_PHYSICIAN",
    },
    {
      name: "Application Admin",
      icn: "bi bi-person-lines-fill fs-1",
      val: "ROLE_APPLICATION_ADMIN",
    },
  ];
  const [roleFilter, setRoleFilter] = useState([]);

  useEffect(() => {
    const filterArr = listRole.filter((item) => roleList.includes(item.val));
    setRoleFilter(filterArr);
  }, []);

  return (
    <Modal show={isOpen} onHide={handleClick} size="lg" centered>
      <Modal.Header closeButton>
        <Modal.Title>Select Role</Modal.Title>
      </Modal.Header>

      <Modal.Body>
        <div className="bg-white p-3">
          <div className="row justify-content-evenly p-2 m-3">
            {roleFilter.map((item) => (
              <div className="col-4 mb-4" key={item.val}>
                <button
                  type="button"
                  className="card border-dark shadow align-items-center w-100 h-100 p-3 m-0"
                  id="ROLE_ADMIN"
                  onClick={() => roleSelect(`${item.val}`)}
                >
                  <div className="text-center">
                    <i className={item.icn} />
                  </div>
                  <div className="text-center text-bold p-3">{item.name}</div>
                </button>
              </div>
            ))}

            {/* <div className="col-4 mb-4">
              <button
                type="button"
                className="card border-dark shadow align-items-center w-100 h-100 p-3 m-0"
                id="ROLE_ADMIN"
                onClick={() => roleSelect("ROLE_ADMIN")}
              >
                <div className="text-center">
                  <i className="bi bi-shield-lock-fill fs-1" />
                </div>
                <div className="text-center text-bold p-3">Admin Office</div>
              </button>
            </div>

            <div className="col-4 mb-4">
              <button
                type="button"
                className="card border-dark shadow align-items-center w-100 h-100 p-3 m-0"
                id="ROLE_CARE_MANAGER"
                onClick={() => roleSelect("ROLE_CARE_MANAGER")}
              >
                <div className="text-center">
                  <i className="bi bi-person-badge fs-1" />
                </div>
                <div className="text-center text-bold p-3">Care Manager</div>
              </button>
            </div>

            <div className="col-4 mb-4">
              <button
                type="button"
                className="card border-dark shadow align-items-center w-100 h-100 p-3 m-0"
                id="ROLE_CASE_MANAGER"
                onClick={() => roleSelect("ROLE_CASE_MANAGER")}
              >
                <div className="text-center">
                  <i className="bi bi-person-workspace fs-1" />
                </div>
                <div className="text-center text-bold p-3">Case Manager</div>
              </button>
            </div>
            <div className="col-4 mb-4">
              <button
                type="button"
                className="card border-dark shadow align-items-center w-100 h-100 p-3 m-0"
                id="ROLE_CARE_GIVER"
                onClick={() => roleSelect("ROLE_CARE_GIVER")}
              >
                <div className="text-center">
                  <i className="bi bi-person-hearts fs-1" />
                </div>
                <div className="text-center text-bold p-3">Care Giver</div>
              </button>
            </div>
            <div className="col-4 mb-4">
              <button
                type="button"
                className="card border-dark shadow align-items-center w-100 h-100 p-3 m-0"
                id="ROLE_CARE_PHYSICIAN"
                onClick={() => roleSelect("ROLE_CARE_PHYSICIAN")}
              >
                <div className="text-center">
                  <i className="bi bi-bandaid-fill fs-1" />
                </div>
                <div className="text-center text-bold p-3">Primary Care Physician</div>
              </button>
            </div>
            <div className="col-4 mb-4">
              <button
                type="button"
                className="card border-dark shadow align-items-center w-100 h-100 p-3 m-0"
                id="ROLE_APPLICATION_ADMIN"
                onClick={() => roleSelect("ROLE_APPLICATION_ADMIN")}
              >
                <div className="text-center">
                  <i className="bi bi-person-lines-fill fs-1" />
                </div>
                <div className="text-center text-bold p-3">Application Admin</div>
              </button>
            </div> */}
          </div>

          {/* <div className="d-flex justify-content-evenly p-2 m-3">
            <button
              type="button"
              className="card border-dark shadow align-items-center w-25 p-3"
              id="ROLE_ADMIN"
              onClick={() => roleSelect("ROLE_ADMIN")}
            >
              <div className="text-center">
                <i className="bi bi-shield-lock-fill fs-1" />
              </div>
              <div className="text-center text-bold p-3">Admin Office</div>
            </button>

            <button
              type="button"
              className="card border-dark shadow align-items-center w-25 p-3"
              id="ROLE_CARE_MANAGER"
              onClick={() => roleSelect("ROLE_CARE_MANAGER")}
            >
              <div className="text-center">
                <i className="bi bi-person-badge fs-1" />
              </div>
              <div className="text-center text-bold p-3">Care Manager</div>
            </button>

            <button
              type="button"
              className="card border-dark shadow align-items-center w-25 p-3"
              id="ROLE_CASE_MANAGER"
              onClick={() => roleSelect("ROLE_CASE_MANAGER")}
            >
              <div className="text-center">
                <i className="bi bi-person-workspace fs-1" />
              </div>
              <div className="text-center text-bold p-3">Case Manager</div>
            </button>
          </div>
          <div className="d-flex justify-content-evenly p-2 m-3">
            <button
              type="button"
              className="card border-dark shadow align-items-center w-25 p-3"
              id="ROLE_CARE_GIVER"
              onClick={() => roleSelect("ROLE_CARE_GIVER")}
            >
              <div className="text-center">
                <i className="bi bi-person-hearts fs-1" />
              </div>
              <div className="text-center text-bold p-3">Care Giver</div>
            </button>

            <button
              type="button"
              className="card border-dark shadow align-items-center w-25 p-3"
              id="ROLE_CARE_PHYSICIAN"
              onClick={() => roleSelect("ROLE_CARE_PHYSICIAN")}
            >
              <div className="text-center">
                <i className="bi bi-bandaid-fill fs-1" />
              </div>
              <div className="text-center text-bold p-3">Primary Care Physician</div>
            </button>

            <button
              type="button"
              className="card border-dark shadow align-items-center w-25 p-3"
              id="ROLE_APPLICATION_ADMIN"
              onClick={() => roleSelect("ROLE_APPLICATION_ADMIN")}
            >
              <div className="text-center">
                <i className="bi bi-person-lines-fill fs-1" />
              </div>
              <div className="text-center text-bold p-3">Application Admin</div>
            </button>
          </div> */}
        </div>
      </Modal.Body>
    </Modal>
  );
};

export default RoleSelection;
