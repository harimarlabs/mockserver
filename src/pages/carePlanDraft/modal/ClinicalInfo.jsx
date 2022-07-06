import React, { useState, useEffect, Fragment } from "react";
import axios from "axios";
import { useForm, useFieldArray } from "react-hook-form";
import API from "../../../util/apiService";

const ClinicalInfo = () => {
  const recomandData = {
    captureValue: false,
    careElement: "",
    days: 0,
    frequncy: "",
    intervals: 0,
    noTimes: 0,
    recommendation: "",
    startFrom: 0,
  };
  const [recommendationList, setRecommendationList] = useState([]);
  const [careElementList, setCareElementList] = useState([]);

  const [careElementDetails, setCareElementDetails] = useState([recomandData]);

  const uniqueId = () => Math.floor(Math.random() * new Date());

  const { register, control, handleSubmit } = useForm();
  const { fields, remove, append } = useFieldArray({
    control,
    name: "careElementDetails",
  });

  const registerSubmit = (data) => {
    console.log(data);
  };

  const recommendations = async () => {
    try {
      // const { data } = await axios.get(`http://localhost:9006/api/v1.0/carerecommendations`);

      const { data } = await API.get(`/careplan/api/v1.0/carerecommendations`);
      // const data = [
      //   { id: 1, title: "Monitor vitals", careElements: [{ id: 1, title: "BP" }] },
      //   {
      //     id: 2,
      //     title: "Monitor vitals1",
      //     careElements: [
      //       { id: 1, title: "High BP" },
      //       { id: 2, title: "Low BP" },
      //       { id: 3, title: "Low BP1" },
      //       { id: 4, title: "Low BP2" },
      //       { id: 5, title: "Low BP3" },
      //       { id: 6, title: "Low BP6" },
      //     ],
      //   },
      //   { id: 3, title: "Monitor vitals2", careElements: [{ id: 1, title: "BP3" }] },
      //   { id: 4, title: "Monitor vitals3", careElements: [{ id: 1, title: "BP4" }] },
      //   { id: 5, title: "Monitor vitals4", careElements: [{ id: 1, title: "BP5" }] },
      //   { id: 6, title: "Monitor vitals5", careElements: [{ id: 1, title: "BP6" }] },
      // ];

      // console.log("data", data);
      setRecommendationList(data);
    } catch (err) {
      console.log(err);
    }
  };

  useEffect(() => {
    recommendations();
  }, []);

  return (
    <form onSubmit={handleSubmit(registerSubmit)}>
      <div className="row mt-4">
        <div className="col-md-12">
          <div className="card card-info">
            <div className="card-header d-flex justify-content-between mb-2">
              <h3 className="card-title text-bold mb-0">Clinical Info</h3>
            </div>

            <div className="card-body p-2">
              <div className="row">
                <div className="col-12">
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
                        >
                          {recommendationList.map((option) => (
                            <option key={option.id} value={option.title}>
                              {option.title}
                            </option>
                          ))}
                        </select>
                      </div>

                      <div className="col-2 border py-2 info-val">
                        <select
                          className="form-select form-select-sm w-100"
                          id="care-element-1"
                          name="careElement"
                          //   value={inputField.careElement}
                          //   onChange={(event) => recommendationChange(index, event)}
                          {...register(`careElementDetails[${index}].careElement`)}
                          defaultValue={inputField.careElement}
                        >
                          <option value="bp" defaultValue>
                            BP
                          </option>
                          <option value="temperature">Temperature</option>
                          <option value="heart-rate">Heart rate</option>
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
                          <option value="daily" defaultValue>
                            Daily
                          </option>
                          <option value="weekly">Weekly</option>
                          <option value="monthly">Monthly</option>
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
                        <button type="button" onClick={() => remove(index)}>
                          -
                        </button>
                      </div>
                    </div>
                  ))}
                  <button type="button" onClick={() => append(recomandData)}>
                    +
                  </button>
                </div>
              </div>
            </div>

            <button type="submit">Submit</button>
          </div>
        </div>
      </div>
    </form>
  );
};

export default ClinicalInfo;
