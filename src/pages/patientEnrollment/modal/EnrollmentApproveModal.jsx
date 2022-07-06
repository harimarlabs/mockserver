import React, { useState, useEffect } from "react";
import axios from "axios";
import { toast } from "react-toastify";
import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";
import Tabs from "react-bootstrap/Tabs";
import Tab from "react-bootstrap/Tab";
import { useSelector } from "react-redux";

import API from "../../../util/apiService";

import PreviousDetails from "./PreviousDetails";
import PatientEnrollmentInfo from "./PatientEnrollmentInfo";
import ContactAndDischarge from "../modalTab/ContactAndDischarge";
import DiagnosisAndRecommendations from "../modalTab/DiagnosisAndRecommendations";
import ClinicalInfo from "../modalTab/ClinicalInfo";

const EnrollmentApproveModal = ({ isOpen, handleClick, patient }) => {
  const [isPrevious, setIsPrevious] = useState(false);
  const [loading, setLoading] = useState(false);
  const { user } = useSelector((state) => state.auth);
  const [viewData, setViewData] = useState({});
  const [careManager, setCareManager] = useState([]);
  const [vewPreviousData, setViewPreviousData] = useState([]);
  const [cciScore, setCciScore] = useState(null);

  const fetchData = async () => {
    setLoading(true);
    // const { data } = await axios.get(`http://localhost:9008/api/v1.0/patients/${patient.id}`);
    const { data } = await API.get(`/patientenrollment/api/v1.0/patients/${patient.id}`);
    if (data.id) {
      const cciScor = await API.get(`/patientenrollment/api/v1.0/patients/${data.id}/cci`);
      setCciScore(cciScor.data);
    }

    if (data?.careManager) {
      const res = await API.get(`/authentication/api/v1.0/users/${data.careManager}`);
      setCareManager(res?.data);
    }

    setViewData(data);

    if (data.contacts) {
      const showData = data.contacts.filter((item) => !item.latest);
      setViewPreviousData(showData);
    }

    setLoading(false);
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleApprove = async () => {
    try {
      // const { data } = await axios.patch(
      //   `http://localhost:9008/api/v1.0/patients/${patient.id}/status/`,
      //   {
      //     modifiedBy: user.userId,
      //     status: "Assigned",
      //   },
      // );

      const { data } = await API.patch(
        `/patientenrollment/api/v1.0/patients/${patient.id}/status/`,

        {
          modifiedBy: user.userId,
          status: "Assigned",
        },
      );

      toast.success("Approved Successfully");
      handleClick();
    } catch (err) {
      toast.error(`${err.response.data}`);
    }
  };

  return (
    <>
      <Modal show={isOpen} onHide={handleClick} size="xl" centered>
        <Modal.Header closeButton>
          <Modal.Title>Approve Patient Enrollment</Modal.Title>
        </Modal.Header>

        {viewData && (
          <Modal.Body>
            <PatientEnrollmentInfo viewData={viewData} careData={careManager} />

            <div className="row">
              <div className="col-12">
                <Tabs defaultActiveKey="first">
                  <Tab eventKey="first" title="Contact & Discharge Info">
                    <ContactAndDischarge
                      viewData={viewData}
                      setIsPrevious={setIsPrevious}
                      isPrevious={isPrevious}
                    />
                  </Tab>

                  <Tab eventKey="second" title="Diagnosis / Recommendations">
                    <DiagnosisAndRecommendations viewData={viewData} />
                  </Tab>
                  <Tab eventKey="third" title="Clinical Info">
                    <ClinicalInfo viewData={viewData} cciScore={cciScore} />
                  </Tab>
                </Tabs>
              </div>
            </div>
          </Modal.Body>
        )}
        <Modal.Footer>
          <Button variant="secondary" onClick={handleClick}>
            Cancel
          </Button>

          <Button variant="primary" onClick={handleApprove}>
            Approve
          </Button>
        </Modal.Footer>
      </Modal>

      {viewData && vewPreviousData && (
        <PreviousDetails
          data={vewPreviousData}
          handleClick={() => setIsPrevious(!isPrevious)}
          isOpen={isPrevious}
        />
      )}
    </>
  );
};

export default EnrollmentApproveModal;
