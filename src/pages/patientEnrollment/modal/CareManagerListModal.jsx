import React, { useEffect, useState } from "react";
import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";
import Select from "react-select";
import axios from "axios";
import API from "../../../util/apiService";
// import AsyncSelect from "react-select/async";

const CareManagerListModal = ({ isOpen, handleClick, isProceed, action }) => {
  const [careManger, setCareManger] = useState(null);
  const [careMangerList, setCareMangerList] = useState([]);

  const getCareManagerList = async () => {
    // const { data } = await axios.get(`http://localhost:9003/api/v1.0/roles/name/ROLE_CARE_MANAGER`);
    const { data } = await API.get(`/authentication/api/v1.0/roles/name/ROLE_CARE_MANAGER`);
    console.log("users", data.users);
    const list = data.users.map((item) => {
      return {
        value: item.id,
        label: item.loginId,
      };
    });

    setCareMangerList(list);
  };

  useEffect(() => {
    getCareManagerList();
  }, []);

  const handleAssign = (e) => {
    e.preventDefault();
    isProceed(careManger.value);
    handleClick();
  };

  return (
    <Modal show={isOpen} onHide={handleClick} size="lg" centered>
      <Modal.Header closeButton>
        <Modal.Title>Select Care Manager </Modal.Title>
      </Modal.Header>

      <Modal.Body>
        <form onSubmit={handleAssign}>
          {careMangerList?.length > 0 && (
            <div className="row">
              {/* <div className="col-3">
                  <h3 className="card-title">Patient List</h3>
                </div> */}
              <div className="col-5">
                <Select
                  defaultValue={careManger}
                  onChange={setCareManger}
                  options={careMangerList}
                />
              </div>
              <div className="col-5">
                <button type="button" onClick={handleAssign} className="btn btn-primary">
                  Proceed
                </button>
              </div>
            </div>
          )}
        </form>
      </Modal.Body>
    </Modal>
  );
};

export default CareManagerListModal;
