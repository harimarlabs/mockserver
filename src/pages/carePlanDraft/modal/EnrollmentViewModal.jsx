import React, { useState, useEffect } from "react";
import axios from "axios";

import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";
import Tabs from "react-bootstrap/Tabs";
import Tab from "react-bootstrap/Tab";
import { toast } from "react-toastify";
import { useSelector } from "react-redux";

import API from "../../../util/apiService";
import PreviousDetails from "../../patientEnrollment/modal/PreviousDetails";
// import CareManagerListModal from "../../patientEnrollment/modal/CareManagerListModal";
import PatientEnrollmentInfo from "../../patientEnrollment/modal/PatientEnrollmentInfo";
import ContactAndDischarge from "../../patientEnrollment/modalTab/ContactAndDischarge";
import DiagnosisAndRecommendations from "../../patientEnrollment/modalTab/DiagnosisAndRecommendations";
import ClinicalInfo from "../../patientEnrollment/modalTab/ClinicalInfo";

const EnrollmentViewModal = ({ isOpen, handleClick, patient, role, action }) => {
  // const { user } = useSelector((state) => state.auth);

  const [isPrevious, setIsPrevious] = useState(false);
  const [loading, setLoading] = useState(false);
  // const [openCareManager, setOpenCareManager] = useState(false);
  const [viewData, setViewData] = useState({});
  const [careManager, setCareManager] = useState([]);
  const [vewPreviousData, setViewPreviousData] = useState([]);
  const [cciScore, setCciScore] = useState(null);

  const fetchData = async () => {
    setLoading(true);
    console.log("patient", patient);
    try {
      // const { data } = await API.get(`/patientenrollment/api/v1.0/patients/${patient.id}`);
      const { data } = await API.get(
        `/patientenrollment/api/v1.0/patients/enrollmentId/${patient.entrollmentId}`,
      );

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
    } catch (err) {
      toast.error(`${err.response.data}`);
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  // const checkProceed = async (selectedId) => {
  //   try {
  //     const { data } = await API.patch(
  //       `/patientenrollment/api/v1.0/patients/${patient.id}/caremanager/`,
  //       {
  //         modifiedBy: user.userId,
  //         careManager: selectedId,
  //       },
  //     );
  //     toast.success("Care Manager Assigned Successfully");
  //     handleClick();
  //   } catch (err) {
  //     toast.error(`${err.response.data}`);
  //   }
  // };

  // const handleAssign = async () => {
  //   if (role === "ROLE_ADMIN") {
  //     setOpenCareManager(true);
  //   } else {
  //     const confirmBox = window.confirm(
  //       "Do you want to Assign yourself as a Care Manager to Patient?",
  //     );
  //     if (confirmBox === true) {
  //       checkProceed(user.userId);
  //     }
  //   }
  // };

  return (
    <>
      <Modal show={isOpen} onHide={handleClick} size="xl" centered>
        <Modal.Header closeButton>
          <Modal.Title>{action ? "Assign" : "View"} Patient Enrollment </Modal.Title>
        </Modal.Header>

        {viewData && (
          <Modal.Body>
            {careManager && <PatientEnrollmentInfo viewData={viewData} careData={careManager} />}

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
      </Modal>

      {viewData && vewPreviousData && (
        <PreviousDetails
          data={vewPreviousData}
          handleClick={() => setIsPrevious(!isPrevious)}
          isOpen={isPrevious}
        />
      )}

      {/* {openCareManager && (
        <CareManagerListModal
          handleClick={() => setOpenCareManager(!openCareManager)}
          isOpen={openCareManager}
          isProceed={checkProceed}
        />
      )} */}
    </>
  );
};

export default EnrollmentViewModal;
