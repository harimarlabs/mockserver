import { React, useState, useEffect } from "react";
import { useFieldArray } from "react-hook-form";
import API from "../../../util/apiService";

const CareElements = ({ register, control, watch }) => {
  const recomandData = {
    captureValue: false,
    careElement: "",
    days: 0,
    frequncy: "",
    intervals: 0,
    noTimes: 0,
    recommendation: "",
    startFrom: 0,
    isMonitor: false,
  };

  const [recommendationList, setRecommendationList] = useState([]);
  const [careElementList, setCareElementList] = useState([]);
  // const [isMonitorVital, setIsMonitorVital] = useState(false);
  const uniqueId = () => Math.floor(Math.random() * Date.now());

  const { fields, remove, append } = useFieldArray({
    control,
    name: "careElementDetails",
  });

  const recommendations = async () => {
    try {
      // const { data } = await API.get(`/careplan/api/v1.0/carerecommendations`);
      const data = [
        {
          id: 1,
          title: "Monitor Vitals",
          careElements: [
            { id: 1, title: "BP" },
            { id: 2, title: "Heart Rate" },
            { id: 3, title: "Temperature" },
          ],
        },
        {
          id: 2,
          title: "Medication",
          careElements: [
            { id: 1, title: "BP" },
            { id: 2, title: "Heart Rate" },
            { id: 3, title: "Temperature" },
          ],
        },
        {
          id: 3,
          title: "Physiotherapy",
          careElements: [
            { id: 1, title: "BP" },
            { id: 2, title: "Heart Rate" },
            { id: 3, title: "Temperature" },
          ],
        },
      ];

      setRecommendationList(data);
      setCareElementList(data[0]?.careElements);
    } catch (err) {
      console.log(err);
    }
  };

  const changeRecomandation = (e, index) => {
    // console.log("careElementDetails", fields, e.target.value, index);
    // if (e.target.value !== "Monitor Vitals") {
    //   // fields[index].isMonitor = true;
    //   fields = [...fields, ]
    // } else {
    //   // fields[index].isMonitor = false;
    // }
  };

  useEffect(() => {
    // console.log("patient", patient);
    recommendations();
  }, []);

  return (
    <div className="row mt-4">
      <div className="col-md-12">
        <div className="card card-info">
          <div className="card-header d-flex justify-content-between mb-2">
            <div>
              <h3 className="card-title text-bold mb-0">Clinical Info</h3>
            </div>
            <div className="text-end">
              <button
                type="button"
                className="btn btn-primary p-1"
                onClick={() => append(recomandData)}
              >
                + Add Care Elements
              </button>
              {/* <button
              type="button"
              className="btn btn-primary p-1"
              onClick={() => setCarePlan(!isCarePlanSet)}
            >
              SELECT CARE ELEMENTS
            </button> */}
            </div>
          </div>

          <div className="card-body p-2">
            {/* <div className="row"> */}
            {/* <div className="col-12"> */}
            <div className="row text-center">
              <div className="col-1 border py-2 info-key d-flex justify-content-center align-items-center">
                #
              </div>
              <div className="col-2 border py-2 info-key d-flex justify-content-center align-items-center">
                Recommendations
              </div>
              <div className="col-2 border py-2 info-key d-flex justify-content-center align-items-center">
                Care Element
              </div>
              <div className="col-1 border py-2 info-key d-flex justify-content-center align-items-center">
                Frequency
              </div>
              <div className="col-1 border py-2 info-key d-flex justify-content-center align-items-center">
                No.of Time
              </div>
              <div className="col-1 border py-2 info-key d-flex justify-content-center align-items-center">
                Interval
              </div>
              <div className="col-1 border py-2 info-key d-flex justify-content-center align-items-center">
                Periodicity (days)
              </div>
              <div className="col-1 border py-2 info-key d-flex justify-content-center align-items-center">
                Capture Value
              </div>
              <div className="col-1 border py-2 info-key d-flex justify-content-center align-items-center">
                Starting From
              </div>
              <div className="col-1 border py-2 info-val d-flex justify-content-center align-items-center" />
            </div>

            {fields.map((inputField, index) => (
              <div className="row" key={`${inputField}-${uniqueId()}`}>
                <div className="col-1 border py-2 info-val d-flex justify-content-center align-items-center">
                  {index + 1}
                </div>

                <div className="col-2 border py-2 info-val d-flex justify-content-center align-items-center">
                  <select
                    className="form-select form-select-sm w-100"
                    id="recommendations-1"
                    name="recommendation"
                    {...register(`careElementDetails[${index}].recommendation`)}
                    defaultValue={inputField.recommendation}
                    onChange={(e) => changeRecomandation(e, index)}
                  >
                    {recommendationList &&
                      recommendationList.map((option) => (
                        <option key={option.id} value={option.title}>
                          {option.title}
                        </option>
                      ))}
                  </select>
                </div>

                <div className="col-2 border py-2 info-val">
                  {/* {inputField.isMonitor ? (
                    <input
                      type="text"
                      className="infoVal form-control form-control-sm w-100"
                      id="interval-1"
                      name="intervals"
                      {...register(`careElementDetails[${index}].careElement`)}
                      defaultValue={inputField.careElement}
                    />
                  ) : (
                    <select
                      className="form-select form-select-sm w-100"
                      id="care-element-1"
                      name="careElement"
                      {...register(`careElementDetails[${index}].careElement`)}
                      defaultValue={inputField.careElement}
                    >
                      {careElementList.map((option) => (
                        <option key={option.id} value={option.title}>
                          {option.title}
                        </option>
                      ))}
                    </select>
                  )} */}

                  <select
                    className="form-select form-select-sm w-100"
                    id="care-element-1"
                    name="careElement"
                    {...register(`careElementDetails[${index}].careElement`)}
                    defaultValue={inputField.careElement}
                  >
                    {careElementList &&
                      careElementList.map((option) => (
                        <option key={option.id} value={option.title}>
                          {option.title}
                        </option>
                      ))}
                  </select>
                </div>

                <div className="col-1 border py-2 info-val d-flex justify-content-center align-items-center">
                  <select
                    className="infoVal form-select form-select-sm w-100"
                    id="frequency-1"
                    name="frequncy"
                    {...register(`careElementDetails[${index}].frequncy`)}
                    defaultValue={inputField.frequncy}
                  >
                    <option value="DAILY" defaultValue>
                      Daily
                    </option>
                    <option value="WEEKLY">Weekly</option>
                    {/* <option value="Monthly">Monthly</option> */}
                  </select>
                </div>

                <div className="col-1 border py-2 info-val d-flex justify-content-center align-items-center">
                  <input
                    type="text"
                    className="infoVal form-control form-control-sm w-100"
                    id="no-of-time-1"
                    name="noTimes"
                    {...register(`careElementDetails[${index}].noTimes`)}
                    defaultValue={inputField.noTimes}
                  />
                </div>
                <div className="col-1 border py-2 info-val d-flex justify-content-center align-items-center">
                  <input
                    type="text"
                    className="infoVal form-control form-control-sm w-100"
                    id="interval-1"
                    name="intervals"
                    {...register(`careElementDetails[${index}].intervals`)}
                    defaultValue={inputField.intervals}
                  />
                </div>
                <div className="col-1 border py-2 info-val d-flex justify-content-center align-items-center">
                  <input
                    type="text"
                    className="infoVal form-control form-control-sm w-100"
                    id="periodicity-1"
                    name="days"
                    {...register(`careElementDetails[${index}].days`)}
                    defaultValue={inputField.days}
                  />
                </div>

                <div className="col-1 border py-2 info-val">
                  <div className="col-12 pb-2 d-flex justify-content-center align-items-center">
                    <div className="form-check d-flex justify-content-center">
                      <input
                        className="form-check-input form-select-lg"
                        type="checkbox"
                        id="capture-value-1"
                        name="captureValue"
                        {...register(`careElementDetails[${index}].captureValue`)}
                        //   defaultValue={inputField.captureValue}
                      />
                    </div>
                  </div>
                </div>

                <div className="col-1 border py-2 info-val d-flex justify-content-center align-items-center">
                  <input
                    type="text"
                    className="infoVal form-control form-control-sm w-100"
                    id="starting-from"
                    name="startFrom"
                    {...register(`careElementDetails[${index}].startFrom`)}
                    defaultValue={inputField.startFrom}
                  />
                </div>
                <div className="col-1 border py-2 info-val d-flex justify-content-center align-items-center">
                  <button type="button" className="btn btn-danger " onClick={() => remove(index)}>
                    -
                  </button>
                </div>
              </div>
            ))}
            {/* </div> */}
            {/* </div> */}
          </div>
        </div>
      </div>
    </div>
  );
};

export default CareElements;
