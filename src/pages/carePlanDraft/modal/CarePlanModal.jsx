import React, { useState, useEffect, Fragment, useMemo } from "react";
import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";
import Tabs from "react-bootstrap/Tabs";
import Tab from "react-bootstrap/Tab";
import axios from "axios";
import { toast } from "react-toastify";

import { useForm, useFieldArray, Controller } from "react-hook-form";

import { yupResolver } from "@hookform/resolvers/yup";
import * as Yup from "yup";

import API from "../../../util/apiService";
// import SelectCareElement from "./SelectCareElement";
import CareplanInfoStatus from "./CareplanInfoStatus";
import ClinicalInfo from "./ClinicalInfo";
import ClinicalSummary from "../modalTab/ClinicalSummary";
import CareRecommendations from "../modalTab/CareRecommendations";
import CareElements from "../modalTab/CareElements";
import ContactInfo from "../modalTab/ContactInfo";
import CalyxLoader from "../../../components/commons/CalyxLoader";

const CarePlanModal = ({ isOpen, handleClick, patient, isSubmitted }) => {
  const validationSchema = Yup.object().shape({
    // address: Yup.string().required(),
    // phone: Yup.string().required(),
  });

  const [loading, setLoading] = useState(false);
  const [viewData, setViewData] = useState({});
  const [careManager, setCareManager] = useState([]);

  // const [careElementDetails, setCareElementDetails] = useState([]);

  const [postData, setPostData] = useState({});

  const {
    register,
    control,
    handleSubmit,
    reset,
    formState: { errors },
    watch,
    getValues,
  } = useForm({
    defaultValues: viewData,
    resolver: yupResolver(validationSchema),
  });

  const onSubmit = async (data, event) => {
    // console.log("v", data);
    if (event.target.value === "submit") {
      data.action = "APPROVED";
      data.status = "APPROVED";
      console.log(data);
    } else if (event.target.value === "approval") {
      data.action = "PENDING_APPROVAL";
      data.status = "PENDING_APPROVAL";
    } else if (event.target.value === "draft") {
      data.action = "DRAFT";
      data.status = "DRAFT";
    }
    data.otherRecommendation = [{ otherRecommendation: data.otherRecommendation }];

    const obj = { ...viewData, ...data };

    try {
      // const { res } = await axios.put(
      //   `http://localhost:9006/api/v1.0/careplans/${patient.id}/`,
      //   obj,
      // );
      const { res } = await API.put(`/careplan/api/v1.0/careplans/${patient.id}`, obj);

      toast.success("Care Plan Developed Successfully");
      isSubmitted(true);
      handleClick();
    } catch (err) {
      toast.error(`${err.response.data}`);
    }
  };

  const fetchData = async () => {
    setLoading(true);
    const { data } = await API.get(`/careplan/api/v1.0/careplans/${patient.id}`);
    console.log("data?.careManager", data?.careManager);

    if (data?.careManager) {
      const res = await API.get(`/authentication/api/v1.0/users/${data.careManager}`);
      setCareManager(res?.data);
      // console.log("careManager fetched", careManager);
    }

    if (data.moniter) {
      data.moniter = "true";
    } else {
      data.moniter = "false";
    }

    if (data.otherRecommendation && data.otherRecommendation.length > 0) {
      data.otherRecommendation = data.otherRecommendation[0].otherRecommendation;
    }

    setViewData(data);
    reset(data);
    setLoading(false);
  };

  useEffect(() => {
    fetchData();
  }, [reset]);

  const getCareManagerList = async () => {
    // const { data } = await axios.get(`http://localhost:9003/api/v1.0/roles/name/ROLE_CARE_MANAGER`);
    // const { data } = await API.get(`/careplan/api/v1.0/roles/name/ROLE_CARE_MANAGER`);
    // console.log("users", data);
    //   const list = data.users.map((item) => {
    //     return {
    //       value: item.id,
    //       label: item.loginId,
    //     };
    //   });
    //   setCareMangerList(list);
  };

  useEffect(() => {
    // console.log("patient", patient);
    getCareManagerList();
  }, []);

  return (
    <>
      {loading && <CalyxLoader />}
      <Modal show={isOpen} onHide={handleClick} size="xl" centered>
        <Modal.Header closeButton>
          <Modal.Title>Develop Care Plan</Modal.Title>
        </Modal.Header>

        <Modal.Body>
          {viewData && careManager && (
            <CareplanInfoStatus viewData={viewData} careData={careManager} />
          )}

          <div className="row">
            {/* Risk Assessment */}

            {/* Tabs section start here */}
            <div className="col-12">
              <form onSubmit={handleSubmit(onSubmit)}>
                <Tabs defaultActiveKey="first">
                  <Tab eventKey="first" title="Clinical Summary">
                    <ClinicalSummary register={register} viewData={viewData} />
                  </Tab>

                  <Tab eventKey="second" title="Care Recommendations">
                    <CareRecommendations register={register} viewData={viewData} />
                  </Tab>

                  <Tab eventKey="third" title="Care Elements">
                    <CareElements
                      watch={watch}
                      getValues={getValues}
                      register={register}
                      Controller={Controller}
                      control={control}
                    />
                  </Tab>

                  <Tab eventKey="fourth" title="Contact Info">
                    <ContactInfo register={register} />
                  </Tab>
                </Tabs>
              </form>
            </div>
          </div>
        </Modal.Body>
        <Modal.Footer>
          {patient.action === "PENDING_APPROVAL" && (
            <Button variant="primary" value="submit" onClick={handleSubmit(onSubmit)}>
              Approve
            </Button>
          )}
          {patient.action !== "PENDING_APPROVAL" && (
            <>
              <Button variant="primary" value="submit" onClick={handleSubmit(onSubmit)}>
                Submit
              </Button>
              <Button variant="primary" value="approval" onClick={handleSubmit(onSubmit)}>
                Submit for Approval
              </Button>
              <Button variant="primary" value="draft" onClick={handleSubmit(onSubmit)}>
                Save Draft
              </Button>
            </>
          )}
        </Modal.Footer>
      </Modal>

      {/* <SelectCareElement handleClick={() => setCarePlan(!isCarePlanSet)} isOpen={isCarePlanSet} /> */}
    </>
  );
};

export default CarePlanModal;
