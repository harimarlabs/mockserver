import React, { useEffect, useState } from "react";
import axios from "axios";
import moment from "moment";

import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";
import Tabs from "react-bootstrap/Tabs";
import Tab from "react-bootstrap/Tab";
import { useSelector, useDispatch } from "react-redux";

import { useForm } from "react-hook-form";
import { yupResolver } from "@hookform/resolvers/yup";
import * as Yup from "yup";
import { toast } from "react-toastify";
import API from "../../../util/apiService";
import PatientEnrollmentInfo from "./PatientEnrollmentInfo";

const EnrollmentEditModal = ({ isOpen, handleClick, patient, clinicalInfo }) => {
  const [loading, setLoading] = useState(false);
  const [viewData, setViewData] = useState({});
  const [careManager, setCareManager] = useState([]);
  const { user } = useSelector((state) => state.auth);
  const dispatch = useDispatch();

  const validationSchema = Yup.object().shape({
    // address: Yup.string().required(),
    // phone: Yup.string().required(),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm({
    defaultValues: viewData,
    resolver: yupResolver(validationSchema),
  });

  const fetchData = async () => {
    setLoading(true);

    try {
      const { data } = await API.get(`/patientenrollment/api/v1.0/patients/${patient.id}`);
      if (data?.careManager) {
        const res = await API.get(`/authentication/api/v1.0/users/${data.careManager}`);
        setCareManager(res?.data);
      }

      data.contacts = data?.contacts[0];
      if (data && !data?.clinicalInfo) {
        data.clinicalInfo = {};
        data.clinicalInfo.numberOfAdmissionsLastYear = 0;
        data.clinicalInfo.numberOfEmergencyVisitsInLastSixMonths = 0;
        data.clinicalInfo.liverDisease = "None";
        data.clinicalInfo.diabetesMellitus = "None";
        data.clinicalInfo.solidTumor = "None";
        data.clinicalInfo.aids = false;
        data.clinicalInfo.chf = false;
        data.clinicalInfo.connectiveTissueDisease = false;
        data.clinicalInfo.copd = false;
        data.clinicalInfo.cvaTia = false;
        data.clinicalInfo.dementia = false;
        data.clinicalInfo.dischargeFromOncologyService = false;
        data.clinicalInfo.hemiplegia = false;
        data.clinicalInfo.leukemia = false;
        data.clinicalInfo.lowHemoglobinAtDischarge = false;
        data.clinicalInfo.lowSodiumLevelAtDischarge = false;
        data.clinicalInfo.lymphoma = false;
        data.clinicalInfo.moderateToSevereCKD = false;
        data.clinicalInfo.myocardialInfarction = false;
        data.clinicalInfo.pepticUlcerDisease = false;
        data.clinicalInfo.peripheralVascularDisease = false;
      }

      setViewData(data);

      reset(data);
      // console.log("data", data);

      setLoading(false);
    } catch (err) {
      toast.error(`${err.response.data}`);
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [reset]);

  const onSubmit = async (obj) => {
    console.log("obj", obj);

    const dataObj = {};

    delete obj.contacts.id;
    delete obj.contacts.latest;
    delete obj.contacts.empty;
    delete obj.contacts.creationDate;

    delete obj.diagnosisInfo.diagnosisAtAdmission;
    delete obj.diagnosisInfo.diagnosisDuringDischarge;
    // delete obj.contacts.creationDate;
    // delete obj.contacts.creationDate;
    // delete obj.contacts.creationDate;

    // obj.contacts = [obj.contacts];
    // obj.modifiedBy = user.userId;

    dataObj.contacts = [obj.contacts];
    dataObj.modifiedBy = user.userId;
    dataObj.diagnosisInfo = obj.diagnosisInfo;
    dataObj.clinicalInfo = obj.clinicalInfo;

    try {
      const { res } = await API.put(`/patientenrollment/api/v1.0/patients/${patient.id}`, dataObj);

      handleClick();
      clinicalInfo(obj);
      // const { data } = await API.get(`/patientenrollment/api/v1.0/patients/${patient.id}/cci`);

      toast.success("Updated Successfully");
    } catch (err) {
      toast.error(`${err.response.data}`);
    }
  };

  return (
    <Modal show={isOpen} onHide={handleClick} size="xl" centered>
      <Modal.Header closeButton>
        <Modal.Title>Update Patient Enrollment</Modal.Title>
      </Modal.Header>
      {viewData && (
        <Modal.Body>
          {careManager && <PatientEnrollmentInfo viewData={viewData} careData={careManager} />}

          <div className="row">
            <div className="col-12">
              <form onSubmit={handleSubmit(onSubmit)}>
                <Tabs defaultActiveKey="first">
                  <Tab eventKey="first" title="Contact & Discharge Info">
                    <div className="row mt-4">
                      <div className="col-md-6">
                        <div className="card card-info">
                          <div className="card-header">
                            <h3 className="card-title text-bold">Contact Info</h3>
                          </div>
                          <div className="card-body p-2">
                            <div className="mb-3 row ">
                              <label
                                htmlFor="address"
                                className="col-sm-4 text-sm-end info-key text-bold"
                              >
                                Address
                              </label>
                              <div className="col-sm-8">
                                <textarea
                                  id="address"
                                  placeholder="Address"
                                  rows={2}
                                  name="contacts.address"
                                  {...register("contacts.address")}
                                  className="form-control"
                                  // className={`form-control ${errors.address ? "is-invalid" : ""}`}
                                />

                                {/* <div className="invalid-feedback">{errors.address?.message}</div> */}
                              </div>
                            </div>
                            <div className="mb-3 row">
                              <label
                                htmlFor="mobile"
                                className="col-sm-4 text-sm-end info-key text-bold"
                              >
                                Mobile
                              </label>
                              <div className="col-sm-8">
                                <input
                                  id="mobile"
                                  name="contacts.phone"
                                  type="text"
                                  placeholder="Mobile"
                                  {...register("contacts.phone")}
                                  className="form-control"
                                  // className={`form-control ${errors.phone ? "is-invalid" : ""}`}
                                />
                                {/* <div className="invalid-feedback">{errors.phone?.message}</div> */}
                              </div>
                            </div>
                            <div className="mb-3 row">
                              <label
                                htmlFor="econtact"
                                className="col-sm-4 text-sm-end info-key text-bold"
                              >
                                Emergency Contact
                              </label>
                              <div className="col-sm-8">
                                <input
                                  id="econtact"
                                  type="text"
                                  placeholder="Emergency Contact"
                                  name="contacts.emergencyContactPerson"
                                  {...register("contacts.emergencyContactPerson")}
                                  className="form-control"
                                  // className={`form-control ${
                                  //   errors.emergencyContactPerson ? "is-invalid" : ""
                                  // }`}
                                />
                                {/* <div className="invalid-feedback">
                                {errors.emergencyContactPerson?.message}
                              </div> */}
                              </div>
                            </div>
                            <div className="mb-3 row">
                              <label
                                htmlFor="emobile"
                                className="col-sm-4 text-sm-end info-key text-bold"
                              >
                                Emergency Mobile No
                              </label>
                              <div className="col-sm-8">
                                <input
                                  id="emobile"
                                  type="text"
                                  placeholder="Emergency Mobile No"
                                  name="contacts.emergencyContactNo"
                                  {...register("contacts.emergencyContactNo")}
                                  className="form-control"
                                />
                                {/* <div className="invalid-feedback">
                                {errors.emergencyContactNo?.message}
                              </div> */}
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>

                      <div className="col-md-6">
                        <div className="card card-info">
                          <div className="card-header">
                            <h3 className="card-title text-bold">
                              <i className="fas fa-text-width" />
                              Discharge Info
                            </h3>
                          </div>
                          <div className="card-body">
                            <div className="row">
                              <div className="col-6 mb-2">
                                <span className="text-bold pe-2 info-key">Admission Date</span>
                                <span className="info-val">
                                  {moment(
                                    viewData?.dischargeInfo?.admissionDate
                                      ? viewData?.dischargeInfo?.admissionDate
                                      : "-",
                                  ).format("MM/DD/YYYY")}
                                </span>
                              </div>
                              <div className="col-6 mb-2">
                                <span className="text-bold pe-2 info-key">Discharge Date</span>
                                <span className="info-val">
                                  {moment(
                                    viewData?.dischargeInfo?.dischargeDate
                                      ? viewData?.dischargeInfo?.dischargeDate
                                      : "-",
                                  ).format("MM/DD/YYYY")}
                                </span>
                              </div>
                              <div className="col-6 mb-2">
                                <span className="text-bold pe-2 info-key">Method of Admission</span>
                                <span className="info-val">
                                  {viewData?.dischargeInfo?.methodOfAdmission
                                    ? viewData?.dischargeInfo?.methodOfAdmission
                                    : "-"}
                                </span>
                              </div>
                              <div className="col-6 mb-2">
                                <span className="text-bold pe-2 info-key">Hospital Site</span>
                                <span className="info-val">
                                  {viewData?.dischargeInfo?.hospitalSite
                                    ? viewData?.dischargeInfo?.hospitalSite
                                    : "-"}
                                </span>
                              </div>
                              <div className="col-6 mb-2">
                                <span className="text-bold pe-2 info-key">Discharge Method</span>
                                <span className="info-val">
                                  {viewData?.dischargeInfo?.dischargeMethod
                                    ? viewData?.dischargeInfo?.dischargeMethod
                                    : "-"}
                                </span>
                              </div>
                              <div className="col-6 mb-2">
                                <span className="text-bold pe-2 info-key">
                                  Discharge Disposition
                                </span>
                                <span className="info-val">
                                  {viewData?.dischargeInfo?.dischargeDisposition
                                    ? viewData?.dischargeInfo?.dischargeDisposition
                                    : "-"}
                                </span>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </Tab>
                  <Tab eventKey="second" title="Diagnosis / Recommendations">
                    <div className="row mt-4">
                      <div className="col-md-12 mt-2">
                        <div className="card card-info mb-0">
                          <div className="card-header">
                            <h3 className="card-title text-bold">
                              <i className="fas fa-text-width" />
                              Diagnosis Info
                            </h3>
                          </div>
                          <div className="card-body">
                            <div className="row flex-align0center">
                              <div className="col-4 mb-5 d-flex">
                                <div className="text-bold pe-2 info-key w-50">
                                  Provisional Diagnosis
                                </div>
                                <div className="info-val w-50 mb-1">
                                  {viewData?.diagnosisInfo?.diagnosisAtAdmission
                                    ? viewData?.diagnosisInfo?.diagnosisAtAdmission
                                    : "-"}
                                </div>
                              </div>
                              <div className="col-1" />
                              <div className="col-4 mb-2 d-flex">
                                <div className="text-bold pe-2 info-key w-25">ICD Code</div>
                                <div className="info-val w-75">
                                  <input
                                    className="form-control form-control-sm w-100"
                                    type="text"
                                    name="diagnosisInfo.admissionIcdCode"
                                    {...register("diagnosisInfo.admissionIcdCode")}
                                  />
                                </div>
                              </div>
                            </div>
                            <div className="row flex-align0center">
                              <div className="col-4 mb-2 mb-5 d-flex">
                                <div className="text-bold pe-2 info-key w-50">
                                  Discharge Diagnosis
                                </div>
                                <div className="info-val w-50 mb-1">
                                  <div>
                                    {viewData?.diagnosisInfo?.diagnosisDuringDischarge
                                      ? viewData?.diagnosisInfo?.diagnosisDuringDischarge
                                      : "-"}
                                  </div>
                                </div>
                              </div>
                              <div className="col-1" />
                              <div className="col-4 mb-2 d-flex">
                                <div className="text-bold pe-2 info-key w-25">ICD Code</div>
                                <div className="info-val w-75">
                                  <input
                                    className="form-control form-control-sm w-100"
                                    type="text"
                                    name="diagnosisInfo.dischargeIcdCode"
                                    {...register("diagnosisInfo.dischargeIcdCode")}
                                  />
                                </div>
                              </div>
                            </div>
                            <div className="row flex-align0center">
                              <div className="col-4 mb-2 d-flex">
                                <div className="text-bold pe-2 info-key w-50">
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
                      <div className="col-md-12 mt-3">
                        <div className="card card-info">
                          <div className="card-header">
                            <h3 className="card-title text-bold">
                              <i className="fas fa-text-width" />
                              Discharge Recommendations
                            </h3>
                          </div>
                          <div className="card-body">
                            <div className="row">
                              {/* <div className="col-1" /> */}
                              <div className="col-12">
                                <div className="info-val">
                                  {viewData?.dischargeInfo?.dischargeRecommendations
                                    ? viewData?.dischargeInfo?.dischargeRecommendations
                                    : "-"}
                                </div>
                              </div>
                              {/* <div className="col-1" /> */}
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </Tab>
                  <Tab eventKey="third" title="Clinical Info">
                    <div className="row mt-4">
                      <div className="col-md-12">
                        <div className="card card-info">
                          <div className="card-header">
                            <h3 className="card-title text-bold">Clinical Info</h3>
                          </div>
                          <div className="card-body p-2">
                            <div className="row">
                              <div className="col-7">
                                <div className="mb-1 row">
                                  <label htmlFor="ci1" className="col-sm-8 info-key text-bold">
                                    No. of hospital admissions during the previous year
                                  </label>
                                  <div className="col-sm-4">
                                    <input
                                      type="text"
                                      id="ci1"
                                      className="form-control form-control-sm w-100"
                                      placeholder="Enter"
                                      name="clinicalInfo.numberOfAdmissionsLastYear"
                                      {...register("clinicalInfo.numberOfAdmissionsLastYear")}
                                    />
                                    <div className="invalid-feedback">
                                      {errors.numberOfAdmissionsLastYear?.message}
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci1" className="col-sm-8 info-key text-bold">
                                    No. of Visits to emergency department in previous 6 months
                                  </label>
                                  <div className="col-sm-4">
                                    <input
                                      type="text"
                                      id="ci1"
                                      className="form-control form-control-sm w-100"
                                      placeholder="Enter"
                                      name="clinicalInfo.numberOfEmergencyVisitsInLastSixMonths"
                                      {...register(
                                        "clinicalInfo.numberOfEmergencyVisitsInLastSixMonths",
                                      )}
                                    />
                                    <div className="invalid-feedback">
                                      {errors.numberOfEmergencyVisitsInLastSixMonths?.message}
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci6" className="col-sm-8 info-key text-bold">
                                    Liver disease
                                  </label>
                                  <div className="col-sm-4">
                                    <select
                                      id="customSwitch16"
                                      className="form-control form-control-sm form-select w-100"
                                      name="clinicalInfo.liverDisease"
                                      {...register("clinicalInfo.liverDisease")}
                                    >
                                      <option defaultValue>None</option>
                                      <option value="Mild">Mild</option>
                                      <option value="Moderate_To_Severe">Moderate to Severe</option>
                                    </select>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci7" className="col-sm-8 info-key text-bold">
                                    Solid tumor
                                  </label>
                                  <div className="col-sm-4">
                                    <select
                                      id="customSwitch17"
                                      className="form-control form-control-sm form-select w-100"
                                      name="clinicalInfo.solidTumor"
                                      {...register("clinicalInfo.solidTumor")}
                                    >
                                      <option defaultValue>None</option>
                                      <option value="Localized">Localized</option>
                                      <option value="Metastatic">Metastatic</option>
                                    </select>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci8" className="col-sm-8 info-key text-bold">
                                    Diabetes mellitus
                                  </label>
                                  <div className="col-sm-4">
                                    <select
                                      id="customSwitch14"
                                      className="form-control form-control-sm form-select w-100"
                                      name="clinicalInfo.diabetesMellitus"
                                      {...register("clinicalInfo.diabetesMellitus")}
                                    >
                                      <option defaultValue>None</option>
                                      <option value="Uncomplicate">Uncomplicate</option>
                                      <option value="End_organ_damage">End organ damage</option>
                                    </select>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci3" className="col-sm-8 info-key text-bold">
                                    Low Sodium level at discharge (less than 135mmol/L)
                                  </label>
                                  <div className="col-sm-4">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci3"
                                        name="clinicalInfo.lowSodiumLevelAtDischarge"
                                        {...register("clinicalInfo.lowSodiumLevelAtDischarge")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci4" className="col-sm-8 info-key text-bold">
                                    Low Hemoglobin at discharge (less than 12g/dL)
                                  </label>
                                  <div className="col-sm-4">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci4"
                                        name="clinicalInfo.lowHemoglobinAtDischarge"
                                        {...register("clinicalInfo.lowHemoglobinAtDischarge")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci5" className="col-sm-8 info-key text-bold">
                                    Discharge from an Oncology Service
                                  </label>
                                  <div className="col-sm-4">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci5"
                                        name="clinicalInfo.dischargeFromOncologyService"
                                        {...register("clinicalInfo.dischargeFromOncologyService")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci9" className="col-sm-8 info-key text-bold">
                                    Myocardial infarction
                                  </label>
                                  <div className="col-sm-4">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci9"
                                        name="clinicalInfo.myocardialInfarction"
                                        {...register("clinicalInfo.myocardialInfarction")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci11" className="col-sm-8 info-key text-bold">
                                    Peripheral vascular disease
                                  </label>
                                  <div className="col-sm-4">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci11"
                                        name="clinicalInfo.peripheralVascularDisease"
                                        {...register("clinicalInfo.peripheralVascularDisease")}
                                      />
                                    </div>
                                  </div>
                                </div>
                              </div>
                              <div className="col-1" />
                              <div className="col-4">
                                <div className="mb-1 row">
                                  <label htmlFor="ci10" className="col-sm-10 info-key text-bold">
                                    CHF
                                  </label>
                                  <div className="col-sm-2">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci10"
                                        name="clinicalInfo.chf"
                                        {...register("clinicalInfo.chf")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci12" className="col-sm-10 info-key text-bold">
                                    CVA or TIA
                                  </label>
                                  <div className="col-sm-2">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci12"
                                        name="clinicalInfo.cvaTia"
                                        {...register("clinicalInfo.cvaTia")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci13" className="col-sm-10 info-key text-bold">
                                    Dementia
                                  </label>
                                  <div className="col-sm-2">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci13"
                                        name="clinicalInfo.dementia"
                                        {...register("clinicalInfo.dementia")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci14" className="col-sm-10 info-key text-bold">
                                    COPD
                                  </label>
                                  <div className="col-sm-2">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci14"
                                        name="clinicalInfo.copd"
                                        {...register("clinicalInfo.copd")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci15" className="col-sm-10 info-key text-bold">
                                    Connective tissue disease
                                  </label>
                                  <div className="col-sm-2">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci15"
                                        name="clinicalInfo.connectiveTissueDisease"
                                        {...register("clinicalInfo.connectiveTissueDisease")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci16" className="col-sm-10 info-key text-bold">
                                    Peptic ulcer disease
                                  </label>
                                  <div className="col-sm-2">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci16"
                                        name="clinicalInfo.pepticUlcerDisease"
                                        {...register("clinicalInfo.pepticUlcerDisease")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci17" className="col-sm-10 info-key text-bold">
                                    Hemiplegia
                                  </label>
                                  <div className="col-sm-2">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci17"
                                        name="clinicalInfo.hemiplegia"
                                        {...register("clinicalInfo.hemiplegia")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci18" className="col-sm-10 info-key text-bold">
                                    Moderate to severe CKD
                                  </label>
                                  <div className="col-sm-2">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci18"
                                        name="clinicalInfo.moderateToSevereCKD"
                                        {...register("clinicalInfo.moderateToSevereCKD")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci19" className="col-sm-10 info-key text-bold">
                                    Leukemia
                                  </label>
                                  <div className="col-sm-2">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci19"
                                        name="clinicalInfo.leukemia"
                                        {...register("clinicalInfo.leukemia")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci20" className="col-sm-10 info-key text-bold">
                                    Lymphoma
                                  </label>
                                  <div className="col-sm-2">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci20"
                                        name="clinicalInfo.lymphoma"
                                        {...register("clinicalInfo.lymphoma")}
                                      />
                                    </div>
                                  </div>
                                </div>
                                <div className="mb-1 row">
                                  <label htmlFor="ci21" className="col-sm-10 info-key text-bold">
                                    AIDS
                                  </label>
                                  <div className="col-sm-2">
                                    <div className="form-check form-switch">
                                      <input
                                        type="checkbox"
                                        className="form-check-input"
                                        id="ci21"
                                        name="clinicalInfo.aids"
                                        {...register("clinicalInfo.aids")}
                                      />
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
                </Tabs>
              </form>
            </div>
          </div>
        </Modal.Body>
      )}

      <Modal.Footer>
        <Button variant="secondary" onClick={handleClick}>
          Cancel
        </Button>
        <Button variant="primary" onClick={handleSubmit(onSubmit)}>
          Update
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

export default EnrollmentEditModal;
