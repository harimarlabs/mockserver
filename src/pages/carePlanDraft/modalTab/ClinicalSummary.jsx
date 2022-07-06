import { React, Fragment } from "react";
import moment from "moment";

const ClinicalSummary = ({ register, viewData }) => {
  return (
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
                    <div className="text-bold pe-2 info-key w-50">Provisional Diagnosis</div>
                    <div className="info-val w-50 mb-1">
                      {viewData?.diagnosisAdmissions &&
                        viewData?.diagnosisAdmissions.map((item, index) => (
                          <div key={item.id}>
                            {item.icdDescription}
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
                        viewData?.diagnosisAdmissions.map((item) => (
                          <Fragment key={item.id}>{item.icdCode}</Fragment>
                        ))}
                      ,
                    </div>
                  </div>
                </div>
                <div className="row flex-align0center py-2 mb-3">
                  <div className="col-7 mb-2 d-flex">
                    <div className="text-bold pe-2 info-key w-50">Discharge Diagnosis</div>
                    <div className="info-val w-50 mb-1">
                      {viewData?.diagnosisDischarges &&
                        viewData?.diagnosisDischarges.map((item, index) => (
                          <div key={item.id}>
                            {item.icdDescription}
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
                        viewData?.diagnosisDischarges.map((item) => (
                          <Fragment key={item.id}>{item.icdCode}</Fragment>
                        ))}
                    </div>
                  </div>
                </div>
              </div>
              <div className="col-7 mb-2 d-flex">
                <div className="text-bold pe-2 info-key mb-2 w-50">Chronic Conditions</div>
                <div className="info-val w-50">
                  {viewData?.diagnosisInfo?.chronicConditions
                    ? viewData?.diagnosisInfo?.chronicConditions
                    : "-"}
                  {/* <div>High Blood Pressure</div>
                <div>Hypothyroidism</div>
                <div>Hypercholestrolemia</div> */}
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
                    <div className="text-bold w-50 pe-2 info-key">Monitor Patient</div>
                    <div className="w-50 info-val">
                      <div>
                        <label className="form-check form-check-inline info-key">
                          <input
                            className="form-check-input info-val"
                            type="radio"
                            // name="moniter"
                            value
                            {...register("moniter")}
                          />
                          <span className="form-check-label">Yes</span>
                        </label>
                        <label className="form-check form-check-inline info-key">
                          <input
                            className="form-check-input info-val"
                            type="radio"
                            value={false}
                            // name="moniter"
                            {...register("moniter")}
                          />
                          <span className="form-check-label">No</span>
                        </label>
                      </div>
                    </div>

                    {/* <div className="mb-1 row">
                      <label htmlFor="monitorPatient" className="col-sm-10 info-key text-bold">
                        Monitor Patient
                      </label>
                      <div className="col-sm-2">
                        <div className="form-check form-switch">
                          <input
                            type="checkbox"
                            className="form-check-input"
                            id="monitorPatient"
                            name="moniter"
                            {...register("moniter")}
                          />
                        </div>
                      </div>
                    </div> */}
                  </div>
                  <div className="col-12 pb-2 d-flex">
                    <div className="text-bold w-50 pe-2">
                      <label htmlFor="care-plan" className="info-key">
                        Care Plan
                      </label>
                    </div>
                    <div className="w-50 info-val">
                      <input
                        type="text"
                        id="care-plan"
                        className="form-control form-control-sm info-val w-100"
                        name="carePlan"
                        {...register("carePlan")}
                      />
                    </div>
                  </div>
                  <div className="col-12 pb-2 d-flex">
                    <div className="text-bold w-50 pe-2">
                      <label htmlFor="duration" className="info-key">
                        Duration (Days)
                      </label>
                    </div>
                    <div className="w-50 info-val">
                      <input
                        type="text"
                        id="duration"
                        className="form-control form-control-sm info-val w-100"
                        name="duration"
                        {...register("duration")}
                      />
                    </div>
                  </div>
                  <div className="col-12 pb-2 d-flex">
                    <div className="text-bold w-50 pe-2">
                      <label htmlFor="plan-start-date" className="info-key">
                        Plan Start Date
                      </label>
                    </div>
                    <div className="w-50 info-val">
                      {moment(viewData?.startDate ? viewData?.startDate : "-").format("MM/DD/YYYY")}
                    </div>
                  </div>
                  <div className="col-12 pb-2 d-flex">
                    <div className="text-bold w-50 pe-2">
                      <label htmlFor="plan-end-date" className="info-key">
                        Plan End Date
                      </label>
                    </div>
                    <div className="w-50 info-val">
                      {moment(viewData?.endDate ? viewData?.endDate : "-").format("MM/DD/YYYY")}
                    </div>
                  </div>
                  <div className="col-12 pb-2 d-flex">
                    <div className="text-bold w-50 pe-2">
                      <label htmlFor="monitor-plan-adherence" className="info-key">
                        Monitor Plan Adherence (Days)
                      </label>
                    </div>
                    <div className="w-50 info-val">
                      <input
                        type="text"
                        id="duration"
                        className="form-control form-control-sm w-100"
                        name="currentDay"
                        {...register("currentDay")}
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
  );
};

export default ClinicalSummary;
