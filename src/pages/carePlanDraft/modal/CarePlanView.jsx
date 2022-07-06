import React, { useState, useEffect, Fragment } from "react";
import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";
import Tabs from "react-bootstrap/Tabs";
import Tab from "react-bootstrap/Tab";
import axios from "axios";
import { toast } from "react-toastify";
import moment from "moment";

import { useForm, useFieldArray } from "react-hook-form";

import { yupResolver } from "@hookform/resolvers/yup";
import * as Yup from "yup";

import API from "../../../util/apiService";
// import SelectCareElement from "./SelectCareElement";
import CareplanInfoStatus from "./CareplanInfoStatus";
import ClinicalInfo from "./ClinicalInfo";
import CalyxLoader from "../../../components/commons/CalyxLoader";

const CarePlanView = ({ isOpen, handleClick, patient }) => {
  const [loading, setLoading] = useState(false);
  const [viewData, setViewData] = useState({});
  // const [recommendationList, setRecommendationList] = useState([]);
  // const [careElementList, setCareElementList] = useState([]);
  const [careManager, setCareManager] = useState([]);
  const uniqueId = () => Math.floor(Math.random() * Date.now());

  const fetchData = async () => {
    setLoading(true);
    // const { data } = await axios.get(`http://localhost:9006/api/v1.0/careplans/${patient.id}`);
    const { data } = await API.get(`/careplan/api/v1.0/careplans/${patient.id}`);
    if (data?.careManager) {
      const res = await API.get(`/authentication/api/v1.0/users/${data.careManager}`);
      setCareManager(res?.data);
    }

    setViewData(data);
    setLoading(false);
  };

  useEffect(() => {
    // console.log("patient", patient);
    fetchData();
    // getCareManagerList();
  }, []);

  return (
    <>
      {loading && <CalyxLoader />}
      <Modal show={isOpen} onHide={handleClick} size="xl" centered>
        <Modal.Header closeButton>
          <Modal.Title>View Care Plan</Modal.Title>
        </Modal.Header>

        <Modal.Body>
          {viewData && careManager && (
            <CareplanInfoStatus viewData={viewData} careData={careManager} />
          )}

          {viewData && (
            <div className="row">
              <div className="col-12">
                <Tabs defaultActiveKey="first">
                  <Tab eventKey="first" title="Clinical Summary">
                    <div className="row mt-4">
                      <div className="col-md-7 mt-2">
                        <div className="card card-info mb-0">
                          <div className="card-header p-2">
                            <h3 className="card-title text-bold">
                              <i className="fas fa-text-width" />
                              Diagnosis Info
                            </h3>
                          </div>
                          <div className="card-body">
                            <div className="row">
                              <div className="col-12">
                                <div className="row flex-align0center py-2 mb-3">
                                  <div className="col-7 mb-2 d-flex">
                                    <div className="text-bold pe-2 info-key w-50">
                                      Provisional Diagnosis
                                    </div>
                                    <div className="info-val w-50 mb-1">
                                      {viewData?.diagnosisAdmissions &&
                                        viewData?.diagnosisAdmissions.map((itm, index) => (
                                          <div key={itm.id}>
                                            {itm.icdDescription}
                                            {/* {index !== viewData?.diagnosisAdmissions?.length && ( */}
                                            <span>,</span>
                                            {/* )} */}
                                          </div>
                                        ))}
                                    </div>
                                  </div>
                                  <div className="col-1" />
                                  <div className="col-4 mb-2 d-flex">
                                    <div className="text-bold pe-2 info-key w-50">ICD Code</div>
                                    <div className="info-val w-50">
                                      {viewData?.diagnosisAdmissions &&
                                        viewData?.diagnosisAdmissions.map((itm) => (
                                          <Fragment key={itm.id}>{itm.icdCode}</Fragment>
                                        ))}
                                      ,
                                    </div>
                                  </div>
                                </div>
                                <div className="row flex-align0center py-2 mb-3">
                                  <div className="col-7 mb-2 d-flex">
                                    <div className="text-bold pe-2 info-key w-50">
                                      Discharge Diagnosis
                                    </div>
                                    <div className="info-val w-50 mb-1">
                                      {viewData?.diagnosisDischarges &&
                                        viewData?.diagnosisDischarges.map((itm, index) => (
                                          <div key={itm.id}>
                                            {itm.icdDescription}
                                            {/* {index !== viewData?.diagnosisDischarges?.length && ( */}
                                            <span>,</span>
                                            {/* )} */}
                                          </div>
                                        ))}
                                    </div>
                                  </div>
                                  <div className="col-1" />
                                  <div className="col-4 mb-2 d-flex">
                                    <div className="text-bold pe-2 info-key w-50">ICD Code</div>
                                    <div className="info-val w-50">
                                      {viewData?.diagnosisDischarges &&
                                        viewData?.diagnosisDischarges.map((itm) => (
                                          <Fragment key={itm.id}>{itm.icdCode}</Fragment>
                                        ))}
                                    </div>
                                  </div>
                                </div>
                              </div>
                              <div className="col-7 mb-2 d-flex">
                                <div className="text-bold pe-2 info-key mb-2 w-50">
                                  Chronic Conditions
                                </div>
                                <div className="info-val w-50">
                                  {viewData?.diagnosisInfo?.chronicConditions
                                    ? viewData?.diagnosisInfo?.chronicConditions
                                    : "-"}
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                      <div className="col-md-5 mt-2">
                        <div className="row">
                          <div className="col-12">
                            <div className="card card-info">
                              <div className="card-header p-2">
                                <h3 className="card-title text-bold">
                                  <i className="fas fa-text-width" />
                                  Care Plan
                                </h3>
                              </div>
                              <div className="card-body p-2">
                                <div className="row">
                                  <div className="col-12 pb-2 d-flex">
                                    <div className="text-bold w-50 pe-2 info-key">
                                      Monitor Patient
                                    </div>
                                    <div className="w-50 info-val">
                                      <div>{viewData?.moniter ? "Yes" : "No"}</div>
                                    </div>
                                  </div>
                                  <div className="col-12 pb-2 d-flex">
                                    <div className="text-bold w-50 pe-2">
                                      <label htmlFor="care-plan" className="info-key">
                                        Care Plan
                                      </label>
                                    </div>
                                    <div className="w-50 info-val">
                                      <div>{viewData?.carePlan ? viewData?.carePlan : "-"}</div>
                                    </div>
                                  </div>
                                  <div className="col-12 pb-2 d-flex">
                                    <div className="text-bold w-50 pe-2">
                                      <label htmlFor="duration" className="info-key">
                                        Duration (Days)
                                      </label>
                                    </div>
                                    <div className="w-50 info-val">
                                      <div>{viewData?.duration ? viewData?.duration : "-"}</div>
                                    </div>
                                  </div>
                                  <div className="col-12 pb-2 d-flex">
                                    <div className="text-bold w-50 pe-2">
                                      <label htmlFor="plan-start-date" className="info-key">
                                        Plan Start Date
                                      </label>
                                    </div>
                                    <div className="w-50 info-val">
                                      {moment(
                                        viewData?.startDate ? viewData?.startDate : "-",
                                      ).format("MM/DD/YYYY")}
                                    </div>
                                  </div>
                                  <div className="col-12 pb-2 d-flex">
                                    <div className="text-bold w-50 pe-2">
                                      <label htmlFor="plan-end-date" className="info-key">
                                        Plan End Date
                                      </label>
                                    </div>
                                    <div className="w-50 info-val">
                                      {moment(viewData?.endDate ? viewData?.endDate : "-").format(
                                        "MM/DD/YYYY",
                                      )}
                                    </div>
                                  </div>
                                  <div className="col-12 pb-2 d-flex">
                                    <div className="text-bold w-50 pe-2">
                                      <label htmlFor="monitor-plan-adherence" className="info-key">
                                        Monitor Plan Adherence (Days)
                                      </label>
                                    </div>
                                    <div className="w-50 info-val">
                                      <div>{viewData?.currentDay ? viewData?.currentDay : "-"}</div>
                                    </div>
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </Tab>
                  <Tab eventKey="second" title="Care Recommendations">
                    <div className="row mt-4">
                      <div className="col-md-6">
                        <div className="card card-info">
                          <div className="card-header p-2">
                            <h3 className="card-title text-bold">Discharge Recommendations</h3>
                          </div>
                          <div className="card-body info-val p-2">
                            {viewData?.recommendation ? viewData?.recommendation : "-"}
                          </div>
                        </div>
                      </div>
                      <div className="col-md-6">
                        <div className="card card-info">
                          <div className="card-header p-2">
                            <h3 className="card-title text-bold">Other Recommendations</h3>
                          </div>
                          <div className="card-body">
                            {viewData?.otherRecommendation &&
                              viewData?.otherRecommendation.length > 0 && (
                                <div>
                                  {viewData?.otherRecommendation[0].otherRecommendation
                                    ? viewData?.otherRecommendation[0].otherRecommendation
                                    : "-"}
                                </div>
                              )}
                          </div>
                        </div>
                      </div>
                    </div>
                  </Tab>

                  <Tab eventKey="third" title="Care Elements">
                    <div className="row mt-4">
                      <div className="col-md-12">
                        <div className="card card-info">
                          <div className="card-header d-flex justify-content-between mb-2">
                            <div>
                              <h3 className="card-title text-bold mb-0">Clinical Info</h3>
                            </div>
                          </div>

                          <div className="card-body px-4 py-2">
                            <div className="row text-center w-100 mx-auto">
                              <div className="col-1 border py-2 info-key d-flex justify-content-center align-items-center">
                                #
                              </div>
                              <div className="col-2 border py-2 info-key d-flex justify-content-center align-items-center">
                                Recommendations
                              </div>
                              <div className="col-2 border py-2 info-key d-flex justify-content-center align-items-center">
                                Care Element
                              </div>
                              <div className="col-2 border py-2 info-key d-flex justify-content-center align-items-center">
                                Frequency
                              </div>
                              <div className="col-1 border py-2 info-key d-flex justify-content-center align-items-center">
                                No. of Time
                              </div>
                              <div className="col-1 border py-2 info-key d-flex justify-content-center align-items-center">
                                Interval
                              </div>
                              <div className="col-1 border py-2 info-key d-flex justify-content-center align-items-center">
                                Periodicity (days)
                              </div>
                              <div className="col-1 border py-2 info-key d-flex justify-content-center align-items-center">
                                Capture Value
                              </div>
                              <div className="col-1 border py-2 info-key d-flex justify-content-center align-items-center">
                                Starting From
                              </div>
                            </div>

                            {viewData?.careElementDetails &&
                              viewData?.careElementDetails.map((inputField, index) => (
                                <div
                                  className="row w-100 mx-auto"
                                  key={`${inputField}-${uniqueId()}`}
                                >
                                  <div className="col-1 border py-2 info-val d-flex justify-content-center align-items-center">
                                    {index + 1}
                                  </div>

                                  <div className="col-2 border py-2 info-val d-flex justify-content-center align-items-center">
                                    <div>{inputField.recommendation}</div>
                                  </div>

                                  <div className="col-2 border py-2 info-val d-flex justify-content-center align-items-center">
                                    <div>{inputField.careElement}</div>
                                  </div>

                                  <div className="col-2 border py-2 info-val d-flex justify-content-center align-items-center">
                                    <div>{inputField.frequncy}</div>
                                  </div>

                                  <div className="col-1 border py-2 info-val d-flex justify-content-center align-items-center">
                                    <div>{inputField.noTimes}</div>
                                  </div>
                                  <div className="col-1 border py-2 info-val d-flex justify-content-center align-items-center">
                                    <div>{inputField.intervals}</div>
                                  </div>
                                  <div className="col-1 border py-2 info-val d-flex justify-content-center align-items-center">
                                    <div>{inputField.days}</div>
                                  </div>

                                  <div className="col-1 border py-2 info-val">
                                    <div className="col-12 pb-2 d-flex justify-content-center align-items-center">
                                      <div>{inputField.captureValue ? "Yes" : "No"}</div>
                                    </div>
                                  </div>

                                  <div className="col-1 border py-2 info-val d-flex justify-content-center align-items-center">
                                    <div>{inputField.startFrom}</div>
                                  </div>
                                </div>
                              ))}
                          </div>
                        </div>
                      </div>
                    </div>
                  </Tab>

                  <Tab eventKey="fourth" title="Contact Info">
                    <div className="row mt-4">
                      <div className="col-md-12">
                        <div className="row">
                          <div className="col-12">
                            <div className="card card-info">
                              <div className="card-body pe-2">
                                <div className="row">
                                  <div className="col-4 pe-2">
                                    <div className="text-bold info-key pe-2 pb-3">
                                      Primary Care Physician
                                    </div>
                                    <div className="row pb-2 d-flex">
                                      <div className="col-4 text-bold pe-2 info-key">
                                        <label
                                          htmlFor="primary-care-physician"
                                          className="info-key"
                                        >
                                          Name
                                        </label>
                                      </div>
                                      <div className="col-7 info-val">
                                        <div>{viewData?.physician ? viewData?.physician : "-"}</div>
                                      </div>
                                      <div className="col-1" />
                                    </div>
                                    <div className="row pb-2 d-flex">
                                      <div className="col-4 text-bold pe-2 info-key">
                                        <label htmlFor="primary-care-physician-contact">
                                          Contact Number
                                        </label>
                                      </div>
                                      <div className="col-7 info-val">
                                        <div>
                                          {viewData?.physicianMobile
                                            ? viewData?.physicianMobile
                                            : "-"}
                                        </div>
                                      </div>
                                      <div className="col-1" />
                                    </div>
                                    <div className="row pb-2 d-flex">
                                      <div className="col-4 text-bold pe-2 info-key">
                                        <label
                                          htmlFor="primary-care-physician-email"
                                          className="info-key"
                                        >
                                          Email ID
                                        </label>
                                      </div>
                                      <div className="col-7 info-val">
                                        <div>
                                          {viewData?.physicianEmail
                                            ? viewData?.physicianEmail
                                            : "-"}
                                        </div>
                                      </div>
                                    </div>
                                  </div>
                                  <div className="col-4 pe-2">
                                    <div className="text-bold info-key pe-2 pb-3">
                                      Primary Case Manager
                                    </div>
                                    <div className="row pb-2 d-flex">
                                      <div className="col-4 text-bold pe-2 info-key">
                                        <label htmlFor="primary-case-manager" className="info-key">
                                          Name
                                        </label>
                                      </div>
                                      <div className="col-7 info-val">
                                        <div>
                                          {viewData?.caseManager ? viewData?.caseManager : "-"}
                                        </div>
                                      </div>
                                      <div className="col-1" />
                                    </div>
                                    <div className="row pb-2 d-flex">
                                      <div className="col-4 text-bold pe-2 info-key">
                                        <label
                                          htmlFor="primary-case-manager-contact"
                                          className="info-key"
                                        >
                                          Contact Number
                                        </label>
                                      </div>
                                      <div className="col-7 info-val">
                                        <div>
                                          {viewData?.caseManagerMobile
                                            ? viewData?.caseManagerMobile
                                            : "-"}
                                        </div>
                                      </div>
                                      <div className="col-1" />
                                    </div>
                                    <div className="row pb-2 d-flex">
                                      <div className="col-4 text-bold pe-2 info-key">
                                        <label
                                          htmlFor="primary-case-manager-email"
                                          className="info-key"
                                        >
                                          Email ID
                                        </label>
                                      </div>
                                      <div className="col-7 info-val">
                                        <div>
                                          {viewData?.caseManagerEmail
                                            ? viewData?.caseManagerEmail
                                            : "-"}
                                        </div>
                                      </div>
                                      <div className="col-1" />
                                    </div>
                                  </div>
                                  <div className="col-4 pe-2">
                                    <div className="text-bold info-key pe-2 pb-3">
                                      Primary Care Giver
                                    </div>
                                    <div className="row pb-2 d-flex">
                                      <div className="col-4 text-bold pe-2 info-key">
                                        <label htmlFor="primary-care-giver" className="info-key">
                                          Name
                                        </label>
                                      </div>
                                      <div className="col-7 info-val">
                                        <div>{viewData?.careGiver ? viewData?.careGiver : "-"}</div>
                                      </div>
                                      <div className="col-1" />
                                    </div>
                                    <div className="col-2" />
                                    <div className="row pb-2 d-flex">
                                      <div className="col-4 text-bold pe-2 info-key">
                                        <label
                                          htmlFor="primary-care-giver-contact"
                                          className="info-key"
                                        >
                                          Contact Number
                                        </label>
                                      </div>
                                      <div className="col-7 info-val">
                                        <div>
                                          {viewData?.careGiverMobile
                                            ? viewData?.careGiverMobile
                                            : "-"}
                                        </div>
                                      </div>
                                      <div className="col-1" />
                                    </div>
                                    <div className="col-2" />
                                    <div className="row pb-2 d-flex">
                                      <div className="col-4 text-bold pe-2 info-key">
                                        <label
                                          htmlFor="primary-care-giver-email"
                                          className="info-key"
                                        >
                                          Email ID
                                        </label>
                                      </div>
                                      <div className="col-7 info-val">
                                        <div>
                                          {viewData?.careGiverEmail
                                            ? viewData?.careGiverEmail
                                            : "-"}
                                        </div>
                                      </div>
                                      <div className="col-1" />
                                    </div>
                                  </div>
                                  <div className="col-1" />
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </Tab>
                </Tabs>
              </div>
            </div>
          )}
        </Modal.Body>
      </Modal>
    </>
  );
};

export default CarePlanView;
