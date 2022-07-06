import React from "react";
import moment from "moment";

const CareplanInfoStatus = ({ viewData, careData }) => {
  return (
    <>
      <div className="row">
        <div className="col-6">
          <div className="card card-info mb-0">
            <div className="card-header">
              <h3 className="card-title text-bold">
                <i className="fas fa-text-width" />
                Patient Info
              </h3>
            </div>
            <div className="card-body">
              <div className="row">
                <div className="col-6 d-flex d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">MR No</div>
                  <div className="w-50 info-val">
                    {viewData.patinentMrn ? viewData.patinentMrn : "-"}
                  </div>
                </div>
                <div className="col-6 d-flex d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Admission No</div>
                  <div className="w-50 info-val">
                    {viewData.admissionNo ? viewData.admissionNo : "-"}
                  </div>
                </div>
                <div className="col-6 d-flex d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Name</div>
                  <div className="w-50 info-val">
                    {viewData.patinentName ? viewData.patinentName : "-"}
                  </div>
                </div>
                <div className="col-6 d-flex d-flex mb-2">
                  <div className="text-bold w-50 pr-2 info-key">Gender</div>
                  <div className="w-50 info-val">
                    {viewData.patinentGender ? viewData.patinentGender : "-"}
                  </div>
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

        {/* Plan status */}
        <div className="col-6">
          <div className="card card-info">
            <div className="card-header">
              <h3 className="card-title text-bold">
                <i className="fas fa-text-width" />
                Plan Status
              </h3>
            </div>
            <div className="card-body">
              <div className="row">
                <div className="col-6 d-flex mb-2">
                  <div className="text-bold w-50 pe-2 info-key">Status</div>
                  <div className="info-val w-50">{viewData.status ? viewData.status : "-"}</div>
                </div>
                <div className="col-6 d-flex mb-2">
                  <div className="text-bold w-50 pe-2 info-key">Enrollment ID</div>
                  <div className="info-val w-50">
                    {viewData.entrollmentId ? viewData.entrollmentId : "-"}
                  </div>
                </div>
                <div className="col-6 d-flex mb-2">
                  <div className="text-bold w-50 pe-2 info-key">Created Date/Time</div>
                  <div className="info-val w-50">
                    {moment(viewData?.startDate ? viewData?.startDate : "-").format("MM/DD/YYYY")}
                  </div>
                </div>
                <div className="col-6 d-flex mb-2">
                  <div className="text-bold w-50 pe-2 info-key">Care Manager</div>
                  <div className="info-val w-50">{careData?.loginId ? careData?.loginId : "-"}</div>
                </div>
                <div className="col-6 d-flex mb-2">
                  <div className="text-bold w-50 pe-2 info-key">Approved By</div>
                  <div className="info-val w-50">
                    {viewData.approvedBy ? viewData.approvedBy : "-"}
                  </div>
                </div>
                <div className="col-6 d-flex mb-2" />
                <div className="col-6 d-flex mb-2">
                  <div className="text-bold w-50 pe-2 info-key">Risk Score</div>
                  <div className="info-val w-50">{viewData?.riskScore}</div>
                </div>
                <div className="col-6 d-flex mb-2">
                  <div className="text-bold w-50 pe-2 info-key">Risk Level</div>
                  <div className="info-val w-50">
                    {viewData.riskLevel ? viewData.riskLevel : "-"}
                  </div>
                </div>
              </div>
            </div>
            {/* /.card-body */}
          </div>
        </div>
      </div>
    </>
  );
};

export default CareplanInfoStatus;
