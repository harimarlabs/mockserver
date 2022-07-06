import React, { useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import { yupResolver } from "@hookform/resolvers/yup";
import API from "../../util/apiService";

const RiskScoring = () => {
  const hospitalScore = {
    lowHemoglobinAtDischarge: false,
    dischargeFromOncologyService: false,
    lowSodiumLevelAtDischarge: false,
    numberOfAdmissionsLastYear: "",
    dischargeIcdCode: false,
    admissionType: "",
    stayDays: "",
    stayDaysChecked: false,
  };

  const laceScore = {
    stayDays: "",
    prevSixMonth: "",
    admission: false,
    cciScore: "5",
  };

  const [loading, setLoading] = useState(false);
  const [riskData, setRiskData] = useState({});
  const [riskScoreVal, setRiskScoreVal] = useState({});

  const [hospScore, setHospScore] = useState(hospitalScore);
  const [laceIndxScore, setLaceIndxScore] = useState(laceScore);

  const [hospitalScoreCard, setHospitalScoreCard] = useState(0);
  const [laceIndexScoreCard, setLaceIndexScoreCard] = useState(0);

  // const [stayDays, setStayDays] = useState(null);

  const {
    register,
    control,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm({
    defaultValues: riskScoreVal,
    // resolver: yupResolver(validationSchema),
  });

  const claCulateDays = (strtDay, endDate) => {
    const date1 = new Date(strtDay);
    const date2 = new Date(endDate);
    const diffTime = Math.abs(date2 - date1);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays + 1;
  };

  const fetchData = async () => {
    setLoading(true);
    try {
      // const { data } = await axios.get(`http://localhost:9008/api/v1.0/patients/${patient.id}`);
      const { data } = await API.get(`/patientenrollment/api/v1.0/patients/53`);
      setHospScore({
        stayDays: claCulateDays(
          data?.dischargeInfo?.admissionDate,
          data?.dischargeInfo?.dischargeDate,
        ),
      });
      // await console.log("res", res);

      setRiskData(data);

      const res = {
        contacts: [
          {
            address: "Test567, Bangalore, India ",
            phone: "9090909090",
            emergencyContactPerson: "TEst Contact",
            emergencyContactNo: "8888888888",
          },
        ],
        diagnosisInfo: {
          admissionIcdCode: "67.56",
          dischargeIcdCode: "67.56, 67.56",
        },
        clinicalInfo: {
          numberOfAdmissionsLastYear: "77",
          numberOfEmergencyVisitsInLastSixMonths: "22",
          liverDisease: "Mild",
          solidTumor: "Localized",
          diabetesMellitus: "Uncomplicate",
          lowSodiumLevelAtDischarge: true,
          lowHemoglobinAtDischarge: true,
          dischargeFromOncologyService: true,
          myocardialInfarction: true,
          peripheralVascularDisease: false,
          chf: true,
          cvaTia: false,
          dementia: false,
          copd: true,
          connectiveTissueDisease: false,
          pepticUlcerDisease: true,
          hemiplegia: true,
          moderateToSevereCKD: false,
          leukemia: true,
          lymphoma: false,
          aids: false,
        },
        modifiedBy: 58,
      };

      res.stayDays = claCulateDays(
        data?.dischargeInfo?.admissionDate,
        data?.dischargeInfo?.dischargeDate,
      );

      // res.stayDays = claCulateDays("27-Feb-2020", "5-Mar-2020");

      reset(res);
      setRiskScoreVal(res);
      setLoading(false);
    } catch (err) {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [reset]);

  const onSubmit = async (data) => {
    console.log("data", data);

    console.log("hospScore", hospScore, laceIndxScore);

    let hospitalScoreResult = 0;
    let laceIndexScoreResult = 0;

    if (hospScore.lowHemoglobinAtDischarge) {
      hospitalScoreResult += 1;
    }

    if (hospScore.dischargeFromOncologyService) {
      hospitalScoreResult += 2;
    }

    if (hospScore.lowSodiumLevelAtDischarge) {
      hospitalScoreResult += 1;
    }

    if (hospScore.dischargeIcdCode) {
      hospitalScoreResult += 1;
    }

    if (hospScore.admissionType === "Urgent or Emergent") {
      hospitalScoreResult += 1;
    }

    if (hospScore.numberOfAdmissionsLastYear === "0-1") {
      hospitalScoreResult += 0;
    } else if (hospScore.numberOfAdmissionsLastYear === "2-5") {
      hospitalScoreResult += 2;
    } else if (hospScore.numberOfAdmissionsLastYear === "more-than-5") {
      hospitalScoreResult += 5;
    }

    if (hospScore.stayDays >= 5 && hospScore.stayDaysChecked) {
      hospitalScoreResult += 2;
    }

    /* LAce Index */
    if (laceIndxScore.admission) {
      laceIndexScoreResult += 1;
    }

    if (laceIndxScore.stayDays === "1") {
      laceIndexScoreResult += 1;
    } else if (laceIndxScore.stayDays === "2") {
      laceIndexScoreResult += 2;
    } else if (laceIndxScore.stayDays === "3") {
      laceIndexScoreResult += 3;
    } else if (laceIndxScore.stayDays === "4") {
      laceIndexScoreResult += 4;
    } else if (laceIndxScore.stayDays === "5") {
      laceIndexScoreResult += 5;
    } else if (laceIndxScore.stayDays === "7") {
      laceIndexScoreResult += 7;
    }

    if (laceIndxScore.prevSixMonth === "1") {
      laceIndexScoreResult += 1;
    } else if (laceIndxScore.prevSixMonth === "2") {
      laceIndexScoreResult += 2;
    } else if (laceIndxScore.prevSixMonth === "3") {
      laceIndexScoreResult += 3;
    } else if (laceIndxScore.prevSixMonth === "4") {
      laceIndexScoreResult += 4;
    }

    if (laceIndxScore.cciScore === 1) {
      laceIndexScoreResult += 1;
    } else if (laceIndxScore.cciScore === 2) {
      laceIndexScoreResult += 2;
    } else if (laceIndxScore.cciScore === 3) {
      laceIndexScoreResult += 3;
    } else if (laceIndxScore.cciScore >= 4) {
      laceIndexScoreResult += 5;
    }

    setHospitalScoreCard(hospitalScoreResult);
    setLaceIndexScoreCard(laceIndexScoreResult);
  };

  const onChangeCheckbox = (e) => {
    setHospScore({ ...hospScore, [e.target.name]: e.target.checked });
  };

  const handleInputChange = (e) => {
    setHospScore({ ...hospScore, [e.target.name]: e.target.value });
  };

  const onChangeCheckboxLace = (e) => {
    setLaceIndxScore({ ...laceIndxScore, [e.target.name]: e.target.checked });
  };

  const handleInputChangeLace = (e) => {
    setLaceIndxScore({ ...laceIndxScore, [e.target.name]: e.target.value });
  };

  return (
    <>
      <h1 className="h3 mb-3">Risk Scoring</h1>
      <form onSubmit={handleSubmit(onSubmit)}>
        <div className="row">
          <div className="col-12">
            <div className="card">
              <div className="card-body">
                <div className="accordion" id="">
                  <div className="accordion-item">
                    <div className="px-3 py-0">
                      <div className="row">
                        <div className="riskList col-7">
                          <div className="row py-2">
                            <div className="col-md-6 text-bold info-key">
                              <label htmlFor="patient-name">Patient Name</label>
                            </div>
                            <div className="col-md-1">:</div>
                            <div className="col-md-5 info-val">
                              {riskData.name ? riskData.name : "-"}
                            </div>
                            <div className="col-2" />
                          </div>
                        </div>
                        <div className="riskList col-5">
                          <div className="row py-2">
                            <div className="col-md-6 text-bold info-key">
                              <label htmlFor="age-gender">Age/Gender</label>
                            </div>
                            <div className="col-md-1">:</div>
                            <div className="col-md-5 info-val">
                              {riskData.age} / {riskData.gender}
                            </div>
                            <div className="col-2" />
                          </div>
                        </div>
                        <div className="riskList col-7">
                          <div className="row py-2">
                            <div className="col-md-6 text-bold info-key">
                              <label htmlFor="mrn">MRN</label>
                            </div>
                            <div className="col-md-1">:</div>
                            <div className="col-md-5 info-val">
                              {riskData.mrNumber ? riskData.mrNumber : "-"}
                            </div>
                            <div className="col-2" />
                          </div>
                        </div>
                        <div className="riskList col-5">
                          <div className="row py-2">
                            <div className="col-md-6 text-bold info-key">
                              <label htmlFor="enrollment-id">Enrollment ID</label>
                            </div>
                            <div className="col-md-1">:</div>
                            <div className="col-md-5 info-val">
                              {riskData.enrollmentId ? riskData.enrollmentId : "-"}
                            </div>
                            <div className="col-2" />
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="accordion-item">
                    <h2 className="accordion-header card-header" id="headingOne">
                      <div className="d-flex card-title card-info p-1 mb-0">
                        <div>Hospital Score</div>
                        <div className="px-3">
                          (Score: {hospitalScoreCard}) :
                          {hospitalScoreCard > 0 && hospitalScoreCard < 5 && <span>Low</span>}
                          {hospitalScoreCard >= 5 && hospitalScoreCard <= 6 && (
                            <span>Moderate</span>
                          )}
                          {hospitalScoreCard > 6 && <span>High</span>}
                        </div>
                      </div>
                    </h2>
                    <div>
                      <div className="px-3 py-0">
                        <div className="row p-2">
                          <div className="riskList col-6 p-2">
                            <div className="row">
                              <div className="col-md-5 text-bold info-key">
                                <label htmlFor="low-haemoglobin-at-discharge">
                                  Low haemoglobin at discharge (less than 12 g/dL)
                                </label>
                              </div>
                              <div className="col-md-1">:</div>
                              <div className="col-4 info-val">
                                <input
                                  id="low-haemoglobin-at-discharge"
                                  type="text"
                                  className="form-control form-control-sm"
                                  // name="lowHemoglobinAtDischarge"
                                  // value={riskScoreVal.lowHemoglobinAtDischarge}
                                  // onChange={handleInputChange}
                                />
                              </div>
                              <div className="col-1">
                                <input
                                  className="form-check-input form-select-lg"
                                  type="checkbox"
                                  id="low-haemoglobin-at-discharge"
                                  name="lowHemoglobinAtDischarge"
                                  value={hospScore.lowHemoglobinAtDischarge}
                                  onChange={onChangeCheckbox}

                                  // name="clinicalInfo.lowHemoglobinAtDischarge"
                                  // {...register("clinicalInfo.lowHemoglobinAtDischarge")}
                                />
                              </div>
                            </div>
                          </div>
                          <div className="riskList col-6 p-2">
                            <div className="row">
                              <div className="col-md-1" />
                              <div className="col-md-5 text-bold info-key">
                                <label htmlFor="discharge-from-oncology-service">
                                  Discharge from an oncology service
                                </label>
                              </div>
                              <div className="col-md-1">:</div>
                              <div className="col-1 info-val">
                                <input
                                  className="form-check-input form-select-lg"
                                  type="checkbox"
                                  id="discharge-from-oncology-service"
                                  name="dischargeFromOncologyService"
                                  value={hospScore.dischargeFromOncologyService}
                                  onChange={onChangeCheckbox}
                                />
                              </div>
                            </div>
                          </div>
                          <div className="riskList col-6 p-2">
                            <div className="row">
                              <div className="col-md-5 text-bold info-key">
                                <label htmlFor="low-sodium-level">
                                  Low sodium level at discharge (less than 135 mmol/L)
                                </label>
                              </div>
                              <div className="col-md-1">:</div>
                              <div className="col-4 info-val">
                                <input
                                  id="low-sodium-level"
                                  type="text"
                                  className="form-control form-control-sm"
                                  // name="lowSodiumLevelAtDischarge"
                                  // value={riskScoreVal.lowSodiumLevelAtDischarge}
                                  // onChange={handleInputChange}
                                />
                              </div>
                              <div className="col-1">
                                <input
                                  className="form-check-input form-select-lg"
                                  type="checkbox"
                                  id="low-sodium-level"
                                  // name="clinicalInfo.lowSodiumLevelAtDischarge"
                                  // {...register("clinicalInfo.lowSodiumLevelAtDischarge")}
                                  name="lowSodiumLevelAtDischarge"
                                  value={hospScore.lowSodiumLevelAtDischarge}
                                  onChange={onChangeCheckbox}
                                />
                              </div>
                            </div>
                          </div>
                          <div className="riskList col-6 p-2">
                            <div className="row">
                              <div className="col-md-1" />
                              <div className="col-5 text-bold info-key">
                                <label htmlFor="procedure-during-hospital-stay">
                                  Procedure during hospital stay (ICD 10 coded)
                                </label>
                              </div>
                              <div className="col-1">:</div>
                              <div className="col-4 info-val">
                                <input
                                  id="procedure-during-hospital-stay"
                                  type="text"
                                  className="form-control form-control-sm"
                                  name="diagnosisInfo.dischargeIcdCode"
                                  {...register("diagnosisInfo.dischargeIcdCode")}
                                />
                              </div>
                              <div className="col-1">
                                <input
                                  className="form-check-input form-select-lg"
                                  type="checkbox"
                                  id="procedure-during-hospital-stay"
                                  name="dischargeIcdCode"
                                  value={hospScore.dischargeIcdCode}
                                  onChange={onChangeCheckbox}
                                />
                              </div>
                            </div>
                          </div>
                          <div className="riskList col-6 p-2">
                            <div className="row">
                              <div className="col-md-5 text-bold info-key">
                                <label htmlFor="index-admission-type">Index admission type</label>
                              </div>
                              <div className="col-md-1">:</div>
                              <div className="col-md-4 info-val">
                                <select
                                  className="form-select form-select-sm"
                                  id="visit-to-emergency"
                                  name="admissionType"
                                  value={hospScore.admissionType}
                                  onChange={handleInputChange}
                                >
                                  <option>Elective</option>
                                  <option>Urgent or Emergent</option>
                                </select>
                              </div>
                            </div>
                          </div>
                          <div className="riskList col-6 p-2">
                            <div className="row">
                              <div className="col-md-1" />
                              <div className="col-md-5 text-bold info-key">
                                <label htmlFor="length-of-hospital-stay">
                                  Length of hospital stay &gt;= 5 days
                                </label>
                              </div>
                              <div className="col-1">:</div>
                              <div className="col-4 info-val">
                                <input
                                  id="length-of-hospital-stay"
                                  type="text"
                                  className="form-control form-control-sm"
                                  name="stayDays"
                                  {...register("stayDays")}
                                  disabled
                                />
                              </div>
                              <div className="col-1">
                                <input
                                  className="form-check-input form-select-lg"
                                  type="checkbox"
                                  id="length-of-hospital-stay"
                                  name="stayDaysChecked"
                                  value={riskScoreVal.stayDaysChecked}
                                  onChange={onChangeCheckbox}
                                />
                              </div>
                            </div>
                          </div>
                          <div className="riskList col-6 p-2">
                            <div className="row">
                              <div className="col-md-5 text-bold info-key">
                                <label htmlFor="hospital-admissions-previous-year">
                                  Number of hospital admissions during the previous year
                                  {/* {riskScoreVal?.clinicalInfo?.numberOfAdmissionsLastYear} */}
                                </label>
                              </div>
                              <div className="col-md-1">:</div>

                              <div className="col-md-4 info-val">
                                <select
                                  className="form-select form-select-sm"
                                  id="hospital-admissions-previous-year"
                                  name="numberOfAdmissionsLastYear"
                                  value={hospScore.numberOfAdmissionsLastYear}
                                  onChange={handleInputChange}
                                >
                                  <option value="0-1">0-1</option>
                                  <option value="2-5">2-5</option>
                                  <option value="more-than-5">&gt;5</option>
                                </select>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="accordion-item hh">
                    <h2 className="accordion-header card-header" id="headingThree">
                      <div className="d-flex card-title card-info p-1 mb-0">
                        <div>Lace Index</div>
                        <div className="px-3">
                          (Score: {laceIndexScoreCard})
                          {laceIndexScoreCard > 0 && laceIndexScoreCard < 5 && <span>Low</span>}
                          {laceIndexScoreCard >= 5 && laceIndexScoreCard <= 9 && (
                            <span>Moderate</span>
                          )}
                          {laceIndexScoreCard > 9 && <span>High</span>}
                        </div>
                      </div>
                    </h2>
                    <div>
                      <div className="px-3 py-0">
                        <div className="row p-2">
                          <div className="riskList col-6 p-2">
                            <div className="row">
                              <div className="col-md-5 text-bold info-key">
                                <label htmlFor="length-of-stay">Length of stay</label>
                              </div>
                              <div className="col-md-1">:</div>
                              <div className="col-md-4 info-val">
                                <select
                                  className="form-select form-select-sm"
                                  id="length-of-stay"
                                  name="stayDays"
                                  value={laceIndxScore.stayDays}
                                  onChange={handleInputChangeLace}
                                >
                                  <option value="1">1 day</option>
                                  <option value="2">2 days</option>
                                  <option value="3">3 days</option>
                                  <option value="4">4-6 days</option>
                                  <option value="5">7-13 days</option>
                                  <option value="7">&gt;= 14 days</option>
                                </select>
                              </div>
                              <div className="col-md-1" />
                            </div>
                          </div>
                          <div className="riskList col-6 p-2">
                            <div className="row">
                              <div className="col-md-1" />
                              <div className="col-md-5 text-bold info-key">
                                <label htmlFor="acute-or-emergent-asmission" readOnly>
                                  Acute or emergent admission
                                </label>
                              </div>
                              <div className="col-md-1">:</div>
                              <div className="col-md-3 info-val">
                                <div>
                                  <input
                                    className="form-check-input form-select-lg"
                                    type="checkbox"
                                    id="acute-or-emergent-asmission"
                                    name="admission"
                                    value={laceIndxScore.admission}
                                    onChange={onChangeCheckboxLace}
                                  />
                                </div>
                              </div>
                            </div>
                          </div>
                          <div className="riskList col-6 p-2">
                            <div className="row">
                              <div className="col-md-5 text-bold info-key">
                                <label htmlFor="visit-to-emergency">
                                  Visits to emergency department in previous six months
                                </label>
                              </div>
                              <div className="col-md-1">:</div>
                              <div className="col-md-4 info-val">
                                <select
                                  className="form-select form-select-sm"
                                  id="visit-to-emergency"
                                  name="prevSixMonth"
                                  value={laceIndxScore.prevSixMonth}
                                  onChange={handleInputChangeLace}
                                >
                                  <option>0</option>
                                  <option>1</option>
                                  <option>2</option>
                                  <option>3</option>
                                  <option>&gt;=4</option>
                                </select>
                              </div>
                            </div>
                          </div>
                          <div className="riskList col-6 p-2">
                            <div className="row">
                              <div className="col-md-1" />
                              <div className="col-md-5 text-bold info-key">
                                <label htmlFor="cci-score" readOnly>
                                  Charlson comorbidity index score
                                </label>
                              </div>
                              <div className="col-md-1">:</div>
                              <div className="col-md-4 info-val">
                                <input
                                  id="cci-score"
                                  type="text"
                                  className="form-control form-control-sm"
                                  value="3"
                                  disabled
                                />
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <div className="d-flex justify-content-end mt-2">
                  <button className="btn btn-info m-2" type="submit">
                    Calculate Score
                  </button>
                  <button className="btn btn-success m-2" type="button">
                    Save
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </form>
    </>
  );
};

export default RiskScoring;
