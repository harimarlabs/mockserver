import React from "react";
import moment from "moment";

const ContactAndDischarge = ({ viewData, setIsPrevious, isPrevious }) => {
  return (
    <div className="row mt-4">
      <div className="col-md-6">
        <div className="card card-info">
          <div className="card-header">
            <h3 className="card-title text-bold">Contact Info</h3>
          </div>

          <div className="card-body p-2">
            <div className="row">
              <div className="col-6 mb-2">
                <span className="text-bold pe-2 info-key">Address</span>
                <span className="info-val">
                  {viewData.contacts?.[0]?.address ? viewData.contacts?.[0]?.address : "-"}
                </span>
              </div>
              <div className="col-6 mb-2">
                <span className="text-bold pe-2 info-key">Mobile</span>
                <span className="info-val">
                  {viewData.contacts?.[0]?.phone ? viewData.contacts?.[0]?.phone : "-"}
                </span>
              </div>
              <div className="col-6 mb-2">
                <span className="text-bold pe-2 info-key">Emergency Contact</span>
                <span className="info-val">
                  {viewData.contacts?.[0]?.emergencyContactPerson
                    ? viewData.contacts?.[0]?.emergencyContactPerson
                    : "-"}
                </span>
              </div>

              <div className="col-6 mb-2">
                <span className="text-bold pe-2 info-key">Emergency Mobile No.</span>
                <span className="info-val">
                  {viewData.contacts?.[0]?.emergencyContactNo
                    ? viewData.contacts?.[0]?.emergencyContactNo
                    : "-"}
                </span>
              </div>
              {viewData.contacts?.length > 1 && (
                <div className="col-6 mb-2">
                  <button
                    type="button"
                    onClick={() => setIsPrevious(!isPrevious)}
                    className="btn btn-link p-0"
                  >
                    View Previous Details
                  </button>
                </div>
              )}
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
                <span className="text-bold pe-2 info-key">Discharge Disposition</span>
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
  );
};

export default ContactAndDischarge;
