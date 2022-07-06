import React, { useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import { yupResolver } from "@hookform/resolvers/yup";
import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";
import { useSelector } from "react-redux";
import { toast } from "react-toastify";

import API from "../../../util/apiService";

const RiskScore = ({ isOpen, handleClick, patient, clinicalData }) => {
  const hospitalScore = {
    lowHemoglobinAtDischarge: false,
    dischargeFromOncologyService: false,
    lowSodiumLevelAtDischarge: false,
    numberOfAdmissionsLastYear: "",
    dischargeIcdCode: false,
    admissionType: "",
    stayDays: "",
    stayDaysChecked: false,

    dischargeIcdCodes: "",
  };

  const laceScore = {
    stayDays: "",
    prevSixMonth: "",
    admission: false,
    cciScore: "",
  };
  const { user } = useSelector((state) => state.auth);

  const [loading, setLoading] = useState(false);
  const [riskData, setRiskData] = useState({});
  const [riskScoreVal, setRiskScoreVal] = useState({});

  const [hospScore, setHospScore] = useState(hospitalScore);
  const [laceIndxScore, setLaceIndxScore] = useState(laceScore);

  const [hospitalScoreCard, setHospitalScoreCard] = useState(0);
  const [laceIndexScoreCard, setLaceIndexScoreCard] = useState(0);

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
      const { data } = await API.get(`/patientenrollment/api/v1.0/patients/${patient.id}`);
      const cciScore = await API.get(`/patientenrollment/api/v1.0/patients/${patient.id}/cci`);

      setRiskData(data);

      const res = { ...clinicalData };

      const hosObj = {
        stayDays: claCulateDays(
          data?.dischargeInfo?.admissionDate,
          data?.dischargeInfo?.dischargeDate,
        ),
        lowHemoglobinAtDischarge: res?.clinicalInfo?.lowHemoglobinAtDischarge,
        dischargeIcdCodes: res?.diagnosisInfo?.dischargeIcdCode,
        dischargeFromOncologyService: res?.clinicalInfo?.dischargeFromOncologyService,
        lowSodiumLevelAtDischarge: res?.clinicalInfo?.lowSodiumLevelAtDischarge,
      };

      if (hosObj.dischargeIcdCodes) {
        hosObj.dischargeIcdCode = true;
      }

      if (hosObj.stayDays) {
        hosObj.stayDaysChecked = true;
      }

      if (
        res?.clinicalInfo?.numberOfAdmissionsLastYear &&
        res?.clinicalInfo?.numberOfAdmissionsLastYear <= 1
      ) {
        hosObj.numberOfAdmissionsLastYear = 0;
      } else if (
        res?.clinicalInfo?.numberOfAdmissionsLastYear &&
        res?.clinicalInfo?.numberOfAdmissionsLastYear > 1 &&
        res?.clinicalInfo?.numberOfAdmissionsLastYear < 5
      ) {
        hosObj.numberOfAdmissionsLastYear = 2;
      } else if (
        res?.clinicalInfo?.numberOfAdmissionsLastYear &&
        res?.clinicalInfo?.numberOfAdmissionsLastYear > 5
      ) {
        hosObj.numberOfAdmissionsLastYear = 5;
      }

      const laceObj = {};
      if (hosObj.stayDays === 1) {
        laceObj.stayDays = 1;
      } else if (hosObj.stayDays === 2) {
        laceObj.stayDays = 2;
      } else if (hosObj.stayDays === 3) {
        laceObj.stayDays = 3;
      } else if (hosObj.stayDays >= 4 && hosObj.stayDays <= 6) {
        laceObj.stayDays = 4;
      } else if (hosObj.stayDays >= 7 && hosObj.stayDays <= 13) {
        laceObj.stayDays = 5;
      } else if (hosObj.stayDays >= 14) {
        laceObj.stayDays = 7;
      }

      if (res?.clinicalInfo?.numberOfEmergencyVisitsInLastSixMonths === 1) {
        laceObj.prevSixMonth = 1;
      } else if (res?.clinicalInfo?.numberOfEmergencyVisitsInLastSixMonths === 2) {
        laceObj.prevSixMonth = 2;
      } else if (res?.clinicalInfo?.numberOfEmergencyVisitsInLastSixMonths === 3) {
        laceObj.prevSixMonth = 3;
      } else if (res?.clinicalInfo?.numberOfEmergencyVisitsInLastSixMonths >= 4) {
        laceObj.prevSixMonth = 4;
      }

      if (cciScore?.data) {
        laceObj.cciScore = cciScore?.data;
      }

      setHospScore({ ...hospitalScore, ...hosObj });
      setLaceIndxScore({ ...laceScore, ...laceObj });

      setLoading(false);
    } catch (err) {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const onSubmitHandle = async () => {
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

    if (hospScore.numberOfAdmissionsLastYear) {
      hospScore.numberOfAdmissionsLastYear = Number(hospScore.numberOfAdmissionsLastYear);
    }

    if (hospScore.numberOfAdmissionsLastYear === 1) {
      hospitalScoreResult += 0;
    } else if (hospScore.numberOfAdmissionsLastYear === 2) {
      hospitalScoreResult += 2;
    } else if (hospScore.numberOfAdmissionsLastYear === 5) {
      hospitalScoreResult += 5;
    }

    if (hospScore.stayDays >= 5 && hospScore.stayDaysChecked) {
      hospitalScoreResult += 2;
    }

    /* LAce Index */
    if (laceIndxScore.admission) {
      laceIndexScoreResult += 1;
    }

    if (laceIndxScore.stayDays) {
      laceIndxScore.stayDays = Number(laceIndxScore.stayDays);
    }

    if (laceIndxScore.stayDays === 1) {
      laceIndexScoreResult += 1;
    } else if (laceIndxScore.stayDays === 2) {
      laceIndexScoreResult += 2;
    } else if (laceIndxScore.stayDays === 3) {
      laceIndexScoreResult += 3;
    } else if (laceIndxScore.stayDays === 4) {
      laceIndexScoreResult += 4;
    } else if (laceIndxScore.stayDays === 5) {
      laceIndexScoreResult += 5;
    } else if (laceIndxScore.stayDays === 7) {
      laceIndexScoreResult += 7;
    }

    if (laceIndxScore.prevSixMonth) {
      laceIndxScore.prevSixMonth = Number(laceIndxScore.prevSixMonth);
    }

    if (laceIndxScore.prevSixMonth === 1) {
      laceIndexScoreResult += 1;
    } else if (laceIndxScore.prevSixMonth === 2) {
      laceIndexScoreResult += 2;
    } else if (laceIndxScore.prevSixMonth === 3) {
      laceIndexScoreResult += 3;
    } else if (laceIndxScore.prevSixMonth === 4) {
      laceIndexScoreResult += 4;
    }

    if (laceIndxScore.cciScore) {
      laceIndxScore.cciScore = Number(laceIndxScore.cciScore);
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

  const onSaveHandle = async () => {
    onSubmitHandle();
    const totalScore = {
      modifiedBy: user.userId,
      riskScore: hospitalScoreCard,
    };

    const { data } = await API.patch(
      `/patientenrollment/api/v1.0/patients/enrollmentId/${riskData.enrollmentId}/riskscore`,
      totalScore,
    );

    toast.success("Risk Score Added Successfully");

    handleClick();
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

  const handleHemoglobin = (data) => {
    if (data >= 12) {
      setHospScore({ ...hospScore, lowHemoglobinAtDischarge: false });
    } else {
      setHospScore({ ...hospScore, lowHemoglobinAtDischarge: true });
    }
  };

  const handleSodium = (data) => {
    if (data >= 135) {
      setHospScore({ ...hospScore, lowSodiumLevelAtDischarge: false });
    } else {
      setHospScore({ ...hospScore, lowSodiumLevelAtDischarge: true });
    }
  };

  return (
    <>
      <Modal show={isOpen} onHide={handleClick} size="xl" centered>
        <Modal.Header closeButton>
          <Modal.Title>Risk Scoring</Modal.Title>
        </Modal.Header>

        <Modal.Body>
          <div className="row">
            <div className="col-12">
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
                        {hospitalScoreCard >= 5 && hospitalScoreCard <= 6 && <span>Moderate</span>}
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
                                Low hemoglobin at discharge (less than 12 g/dL)
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
                                onChange={(e) => handleHemoglobin(e.target.value)}
                              />
                            </div>

                            <div className="col-1">
                              <input
                                className="form-check-input form-select-lg"
                                type="checkbox"
                                id="low-haemoglobin-at-discharge"
                                name="lowHemoglobinAtDischarge"
                                checked={hospScore?.lowHemoglobinAtDischarge}
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
                                checked={hospScore.dischargeFromOncologyService}
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
                                onChange={(e) => handleSodium(e.target.value)}
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
                                checked={hospScore.lowSodiumLevelAtDischarge}
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
                                defaultValue={hospScore?.dischargeIcdCodes}
                                // {...register("diagnosisInfo.dischargeIcdCode")}
                              />
                            </div>
                            <div className="col-1">
                              <input
                                className="form-check-input form-select-lg"
                                type="checkbox"
                                id="procedure-during-hospital-stay"
                                name="dischargeIcdCode"
                                checked={hospScore.dischargeIcdCode}
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
                                {/* ==={hospScore?.stayDays}
                                --defaultValue={console.log(hospScore)} */}
                              </label>
                            </div>
                            <div className="col-1">:</div>
                            <div className="col-4 info-val">
                              <input
                                id="length-of-hospital-stay"
                                type="text"
                                className="form-control form-control-sm"
                                name="stayDays"
                                // {...register("stayDays")}
                                defaultValue={hospScore?.stayDays}
                                disabled
                              />
                            </div>
                            <div className="col-1">
                              <input
                                className="form-check-input form-select-lg"
                                type="checkbox"
                                id="length-of-hospital-stay"
                                name="stayDaysChecked"
                                checked={hospScore?.stayDaysChecked}
                                // value={riskScoreVal.stayDaysChecked}
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
                                <option value="1">0-1</option>
                                <option value="2">2-5</option>
                                <option value="5">&gt;5</option>
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
                        (Score: {laceIndexScoreCard}) :
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
                                <option value="0">0</option>
                                <option value="1">1</option>
                                <option value="2">2</option>
                                <option value="3">3</option>
                                <option value="4">&gt;=4</option>
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
                                value={laceIndxScore.cciScore}
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
            </div>
          </div>
        </Modal.Body>

        <Modal.Footer>
          <Button variant="primary" onClick={onSaveHandle}>
            Save
          </Button>
          <Button variant="primary" onClick={onSubmitHandle}>
            Calculate Score
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  );
};

export default RiskScore;
