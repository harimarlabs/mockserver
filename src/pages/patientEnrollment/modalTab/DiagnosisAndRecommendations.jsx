import React from "react";

const DiagnosisAndRecommendations = ({ viewData }) => {
  return (
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
              <div className="col-6 mb-2">
                <span className="text-bold pe-2 info-key">Provisional Diagnosis</span>
                <span className="info-val">
                  {viewData?.diagnosisInfo?.diagnosisAtAdmission
                    ? viewData?.diagnosisInfo?.diagnosisAtAdmission
                    : "-"}
                </span>
              </div>
              <div className="col-6 mb-2">
                <span className="text-bold pe-2 info-key">Discharge Diagnosis</span>
                <span className="info-val">
                  {viewData?.diagnosisInfo?.diagnosisDuringDischarge
                    ? viewData?.diagnosisInfo?.diagnosisDuringDischarge
                    : "-"}
                </span>
              </div>
              <div className="col-6 mb-2">
                <span className="text-bold pe-2 info-key">ICD Code</span>
                <span className="info-val">
                  {viewData?.diagnosisInfo?.admissionIcdCode
                    ? viewData?.diagnosisInfo?.admissionIcdCode
                    : "-"}
                </span>
              </div>
              <div className="col-6 mb-2">
                <span className="text-bold pe-2 info-key">ICD Code</span>
                <span className="info-val">
                  {viewData?.diagnosisInfo?.dischargeIcdCode
                    ? viewData?.diagnosisInfo?.dischargeIcdCode
                    : "-"}
                </span>
              </div>
              <div className="col-6 mb-2 mt-4">
                <h3 className="text-bold pe-2 info-key">Chronic Conditions</h3>
                <span className="info-val">
                  {viewData?.diagnosisInfo?.chronicConditions
                    ? viewData?.diagnosisInfo?.chronicConditions
                    : "-"}
                </span>
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
              <div className="col-12">
                <span className="info-val">
                  {viewData?.dischargeInfo?.dischargeRecommendations
                    ? viewData?.dischargeInfo?.dischargeRecommendations
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

export default DiagnosisAndRecommendations;
