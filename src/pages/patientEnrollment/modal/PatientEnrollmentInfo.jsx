import React from "react";
import moment from "moment";

const PatientEnrollmentInfo = ({ viewData, careData }) => {
  return (
    <>
      <div className="row">
        <div className="col-md-8">
          <div className="card card-info">
            <div className="card-header">
              <h3 className="card-title text-bold">
                <i className="fas fa-text-width" />
                Patient Info
              </h3>
            </div>
            <div className="card-body p-2">
              <div className="row">
                <div className="col-6 d-flex d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">MR No</div>
                  <div className="w-50 info-val">{viewData.mrNumber ? viewData.mrNumber : "-"}</div>
                </div>
                <div className="col-6 d-flex d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Admission No</div>
                  <div className="w-50 info-val">
                    {viewData.admissionNo ? viewData.admissionNo : "-"}
                  </div>
                </div>
                <div className="col-6 d-flex d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Name</div>
                  <div className="w-50 info-val">{viewData.name ? viewData.name : "-"}</div>
                </div>
                <div className="col-6 d-flex d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Gender</div>
                  <div className="w-50 info-val">{viewData.gender ? viewData.gender : "-"}</div>
                </div>
                <div className="col-6 d-flex d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Age</div>
                  <div className="w-50 info-val">{viewData.age ? viewData.age : "-"}</div>
                </div>
                <div className="col-6 d-flex d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Marital Status</div>
                  <div className="w-50 info-val">{viewData.married ? viewData.married : "-"}</div>
                </div>
                <div className="col-6 d-flex d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Ethnicity</div>
                  <div className="w-50 info-val">
                    {viewData.ethnicity ? viewData.ethnicity : "-"}
                  </div>
                </div>
                <div className="col-6 d-flex d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Occupation</div>
                  <div className="w-50 info-val">
                    {viewData.occupation ? viewData.occupation : "-"}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="col-4">
          <div className="card card-info">
            <div className="card-header">
              <h3 className="card-title text-bold">
                <i className="fas fa-text-width" />
                Enrollment Info
              </h3>
            </div>
            <div className="card-body p-2">
              <div className="row">
                <div className="col-12 d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Enrollment ID</div>
                  <div className="w-50 info-val">
                    {viewData.enrollmentId ? viewData.enrollmentId : "-"}
                  </div>
                </div>
                <div className="col-12 d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Enrollment Date</div>
                  <div className="w-50 info-val">
                    {moment(viewData.enrollmentDate ? viewData.enrollmentDate : "-").format(
                      "MM/DD/YYYY hh:mm a",
                    )}
                  </div>
                </div>
                <div className="col-12 d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Status</div>
                  <div className="w-50 info-val">{viewData.status ? viewData.status : "-"}</div>
                </div>
                <div className="col-12 d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Care Manager</div>
                  <div className="w-50 info-val">{careData?.loginId ? careData?.loginId : "-"}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default PatientEnrollmentInfo;
