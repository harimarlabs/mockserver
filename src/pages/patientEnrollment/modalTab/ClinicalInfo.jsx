import React, { useEffect, useState } from "react";
import API from "../../../util/apiService";

const ClinicalInfo = ({ viewData, cciScore }) => {
  // const [cciScore, setCciScore] = useState(null);

  const fetchData = async () => {
    // console.log("viewData.id", viewData.id);
    // if (viewData.id) {
    //   const { data } = await API.get(`/patientenrollment/api/v1.0/patients/${viewData.id}/cci`);
    //   setCciScore(data);
    // }
  };

  // useEffect(() => {
  //   fetchData();
  // }, []);

  return (
    <div className="row mt-4">
      <div className="col-md-12">
        <div className="card card-info">
          <div className="card-header">
            <h3 className="card-title text-bold">Clinical Info</h3>
          </div>
          {/* {viewData.clinicalInfo && ( */}
          <div className="card-body p-2">
            <div className="row">
              <div className="col-7">
                <div className="mb-1 row">
                  <label htmlFor="ci1" className="col-sm-8 info-key text-bold">
                    No. of hospital admissions during the previous year
                  </label>
                  <div className="col-sm-4">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.numberOfAdmissionsLastYear
                        ? viewData?.clinicalInfo?.numberOfAdmissionsLastYear
                        : "-"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci1" className="col-sm-8 info-key text-bold">
                    No. of Visits to emergency department in previous 6 months
                  </label>
                  <div className="col-sm-4">
                    <span className="info-val">
                      {" "}
                      {viewData?.clinicalInfo?.numberOfEmergencyVisitsInLastSixMonths
                        ? viewData?.clinicalInfo?.numberOfEmergencyVisitsInLastSixMonths
                        : "-"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci6" className="col-sm-8 info-key text-bold">
                    Liver disease
                  </label>
                  <div className="col-sm-4">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.liverDisease
                        ? viewData?.clinicalInfo?.liverDisease
                        : "-"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci7" className="col-sm-8 info-key text-bold">
                    Solid tumor
                  </label>
                  <div className="col-sm-4">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.solidTumor
                        ? viewData?.clinicalInfo?.solidTumor
                        : "-"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci8" className="col-sm-8 info-key text-bold">
                    Diabetes mellitus
                  </label>
                  <div className="col-sm-4">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.diabetesMellitus
                        ? viewData?.clinicalInfo?.diabetesMellitus
                        : "-"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci3" className="col-sm-8 info-key text-bold">
                    Low Sodium level at discharge (less than 135mmol/L)
                  </label>
                  <div className="col-sm-4">
                    <span className="info-val">
                      {/* <pre>{JSON.stringify(viewData?.clinicalInfo, null, 2)}</pre> */}
                      {viewData?.clinicalInfo?.lowSodiumLevelAtDischarge ? "Yes" : "No"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci4" className="col-sm-8 info-key text-bold">
                    Low Hemoglobin at discharge (less than 12g/dL)
                  </label>
                  <div className="col-sm-4">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.lowHemoglobinAtDischarge ? "Yes" : "No"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci5" className="col-sm-8 info-key text-bold">
                    Discharge from an Oncology Service
                  </label>
                  <div className="col-sm-4">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.dischargeFromOncologyService ? "Yes" : "No"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci9" className="col-sm-8 info-key text-bold">
                    Myocardial infarction
                  </label>
                  <div className="col-sm-4">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.myocardialInfarction ? "Yes" : "No"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci11" className="col-sm-8 info-key text-bold">
                    Peripheral vascular disease
                  </label>
                  <div className="col-sm-4">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.peripheralVascularDisease ? "Yes" : "No"}
                    </span>
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
                    <span className="info-val">{viewData?.clinicalInfo?.chf ? "Yes" : "No"}</span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci12" className="col-sm-10 info-key text-bold">
                    CVA or TIA
                  </label>
                  <div className="col-sm-2">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.cvaTia ? "Yes" : "No"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci13" className="col-sm-10 info-key text-bold">
                    Dementia
                  </label>
                  <div className="col-sm-2">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.dementia ? "Yes" : "No"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci14" className="col-sm-10 info-key text-bold">
                    COPD
                  </label>
                  <div className="col-sm-2">
                    <span className="info-val">{viewData?.clinicalInfo?.copd ? "Yes" : "No"}</span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci15" className="col-sm-10 info-key text-bold">
                    Connective tissue disease
                  </label>
                  <div className="col-sm-2">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.connectiveTissueDisease ? "Yes" : "No"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci16" className="col-sm-10 info-key text-bold">
                    Peptic ulcer disease
                  </label>
                  <div className="col-sm-2">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.pepticUlcerDisease ? "Yes" : "No"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci17" className="col-sm-10 info-key text-bold">
                    Hemiplegia
                  </label>
                  <div className="col-sm-2">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.hemiplegia ? "Yes" : "No"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci18" className="col-sm-10 info-key text-bold">
                    Moderate to severe CKD
                  </label>
                  <div className="col-sm-2">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.moderateToSevereCKD ? "Yes" : "No"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci19" className="col-sm-10 info-key text-bold">
                    Leukemia
                  </label>
                  <div className="col-sm-2">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.leukemia ? "Yes" : "No"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci20" className="col-sm-10 info-key text-bold">
                    Lymphoma
                  </label>
                  <div className="col-sm-2">
                    <span className="info-val">
                      {viewData?.clinicalInfo?.lymphoma ? "Yes" : "No"}
                    </span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci21" className="col-sm-10 info-key text-bold">
                    AIDS
                  </label>
                  <div className="col-sm-2">
                    <span className="info-val">{viewData?.clinicalInfo?.aids ? "Yes" : "No"}</span>
                  </div>
                </div>
                <div className="mb-1 row">
                  <label htmlFor="ci21" className="col-sm-10 info-key text-bold">
                    CCI Score
                  </label>
                  <div className="col-sm-2">
                    <span className="info-val">{cciScore}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          {/* // )} */}
        </div>
      </div>
    </div>
  );
};

export default ClinicalInfo;
