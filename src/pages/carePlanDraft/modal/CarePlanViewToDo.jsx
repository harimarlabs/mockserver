import React, { useState, useEffect, Fragment } from "react";
import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";
import Tabs from "react-bootstrap/Tabs";
import Tab from "react-bootstrap/Tab";
import axios from "axios";
import API from "../../../util/apiService";
import CareplanInfoStatus from "./CareplanInfoStatus";

const CarePlanViewToDo = ({ isOpen, handleClick, patient }) => {
  const [todoData, setTodoData] = useState({});
  const [loading, setLoading] = useState(false);
  const [viewData, setViewData] = useState({});
  const [careManager, setCareManager] = useState([]);
  const uniqueId = () => Math.floor(Math.random() * Date.now());

  function createTableCell(data) {
    let maxCol = Math.max(...data.map(({ days }) => days));
    // console.log(maxCol);

    if (maxCol < 30) {
      maxCol = 30;
    }

    for (let index = 0; index < data.length; index++) {
      const element = data[index];
      // console.log("element", element.carePlanTodo);
      const remainLen = maxCol - element.carePlanTodo.length;

      for (let j = 0; j < remainLen; j++) {
        const obj = {
          checked: false,
          day: j,
          id: uniqueId(),
        };
        element.carePlanTodo = [...element.carePlanTodo, obj];
      }

      // console.log("element after add", element.carePlanTodo);
    }

    setTodoData(data);
  }

  const getData = async () => {
    try {
      // const { data } = await axios.get(
      //   `http://localhost:9006/api/v1.0/careplans/${patient.id}/careelementdetails`,
      // );

      const { data } = await API.get(
        `/careplan/api/v1.0/careplans/${patient.id}/careelementdetails`,
      );

      // const data = [
      //   {
      //     id: 1,
      //     recommendation: "Monitor Vitals",
      //     careElement: "BP",
      //     frequncy: "DAILY",
      //     noTimes: 10,
      //     intervals: 5,
      //     days: 15,
      //     captureValue: true,
      //     startFrom: 1,
      //     carePlanTodo: [
      //       { id: 1, day: 1, checked: true },
      //       { id: 2, day: 2, checked: false },
      //       { id: 3, day: 3, checked: false },
      //       { id: 4, day: 4, checked: false },
      //       { id: 5, day: 5, checked: false },
      //       { id: 6, day: 6, checked: true },
      //       { id: 7, day: 7, checked: false },
      //       { id: 8, day: 8, checked: false },
      //       { id: 9, day: 9, checked: false },
      //       { id: 10, day: 10, checked: false },
      //       { id: 11, day: 11, checked: true },
      //       { id: 12, day: 12, checked: false },
      //       { id: 13, day: 13, checked: false },
      //       { id: 14, day: 14, checked: false },
      //       { id: 15, day: 15, checked: false },
      //     ],
      //   },
      //   {
      //     id: 2,
      //     recommendation: "Monitor Vitals",
      //     careElement: "Heart Rate",
      //     frequncy: "WEEKLY",
      //     noTimes: 15,
      //     intervals: 6,
      //     days: 8,
      //     captureValue: true,
      //     startFrom: 1,
      //     carePlanTodo: [
      //       { id: 16, day: 1, checked: true },
      //       { id: 17, day: 2, checked: false },
      //       { id: 18, day: 3, checked: false },
      //       { id: 19, day: 4, checked: false },
      //       { id: 20, day: 5, checked: false },
      //       { id: 21, day: 6, checked: false },
      //       { id: 22, day: 7, checked: true },
      //       { id: 23, day: 8, checked: false },
      //     ],
      //   },
      //   {
      //     id: 3,
      //     recommendation: "Monitor Vitals",
      //     careElement: "BP",
      //     frequncy: "WEEKLY",
      //     noTimes: 5,
      //     intervals: 5,
      //     days: 5,
      //     captureValue: true,
      //     startFrom: 1,
      //     carePlanTodo: [
      //       { id: 24, day: 1, checked: true },
      //       { id: 25, day: 2, checked: false },
      //       { id: 26, day: 3, checked: false },
      //       { id: 27, day: 4, checked: false },
      //       { id: 28, day: 5, checked: false },
      //     ],
      //   },
      //   {
      //     id: 4,
      //     recommendation: "Monitor Vitals",
      //     careElement: "Heart Rate",
      //     frequncy: "WEEKLY",
      //     noTimes: 36,
      //     intervals: 2,
      //     days: 36,
      //     captureValue: true,
      //     startFrom: 2,
      //     carePlanTodo: [
      //       { id: 29, day: 1, checked: false },
      //       { id: 30, day: 2, checked: true },
      //       { id: 31, day: 3, checked: false },
      //       { id: 32, day: 4, checked: true },
      //       { id: 33, day: 5, checked: false },
      //       { id: 34, day: 6, checked: true },
      //       { id: 35, day: 7, checked: false },
      //       { id: 36, day: 8, checked: true },
      //       { id: 37, day: 9, checked: false },
      //       { id: 38, day: 10, checked: true },
      //       { id: 39, day: 11, checked: false },
      //       { id: 40, day: 12, checked: true },
      //       { id: 41, day: 13, checked: false },
      //       { id: 42, day: 14, checked: true },
      //       { id: 43, day: 15, checked: false },
      //       { id: 44, day: 16, checked: true },
      //       { id: 45, day: 17, checked: false },
      //       { id: 46, day: 18, checked: true },
      //       { id: 47, day: 19, checked: false },
      //       { id: 48, day: 20, checked: true },
      //       { id: 49, day: 21, checked: false },
      //       { id: 50, day: 22, checked: true },
      //       { id: 51, day: 23, checked: true },
      //       { id: 52, day: 24, checked: true },
      //       { id: 53, day: 25, checked: true },
      //       { id: 54, day: 26, checked: true },
      //       { id: 55, day: 27, checked: true },
      //       { id: 56, day: 28, checked: true },
      //       { id: 57, day: 29, checked: true },
      //       { id: 58, day: 30, checked: true },
      //       { id: 59, day: 31, checked: true },
      //       { id: 60, day: 32, checked: true },
      //       { id: 61, day: 33, checked: true },
      //       { id: 62, day: 34, checked: true },
      //       { id: 63, day: 35, checked: true },
      //       { id: 64, day: 36, checked: true },
      //     ],
      //   },
      // ];
      createTableCell(data);

      // const shortData = data.sort((a, b) => parseFloat(a.days) - parseFloat(b.days)).reverse();
      // setTodoData(shortData);
    } catch (err) {
      console.log(err);
    }
  };

  const fetchData = async () => {
    setLoading(true);
    // const { data } = await axios.get(`http://localhost:9006/api/v1.0/careplans/${patient.id}`);
    const { data } = await API.get(`/careplan/api/v1.0/careplans/${patient.id}`);
    // const { data } = await API.get(`/careplan/api/v1.0/careplans/27`);

    if (data?.careManager) {
      const res = await API.get(`/authentication/api/v1.0/users/${data.careManager}`);
      setCareManager(res?.data);
    }
    setViewData(data);
    setLoading(false);
  };

  useEffect(() => {
    getData();
    fetchData();
  }, []);

  return (
    <>
      <Modal show={isOpen} onHide={handleClick} size="xl" centered>
        <Modal.Header closeButton>
          <Modal.Title>Task List</Modal.Title>
        </Modal.Header>

        <Modal.Body>
          {viewData && careManager && (
            <CareplanInfoStatus viewData={viewData} careData={careManager} />
          )}
          <div className="row">
            <div className="col-12 mt-3 card p-3">
              <div className="table-scroll-x">
                {todoData.length > 0 &&
                  todoData.map((item, index) => (
                    <div className="row" key={item.id}>
                      <div className="col-1 pe-0">
                        {index === 0 && <div className="text-bold p-1 border text-center">#</div>}
                        <div className="p-1 border text-center">{index + 1}</div>
                      </div>
                      <div className="col-2 p-0">
                        {index === 0 && <div className="text-bold p-1 border">Recommendations</div>}

                        <div className="p-1 border">{item.recommendation}</div>
                      </div>
                      <div className="col-2 p-0">
                        {index === 0 && <div className="text-bold p-1 border">Care Management</div>}
                        <div className="p-1 border">{item.careElement}</div>
                      </div>

                      <div className="col-7 p-0 d-flex white-space">
                        {/* {item.carePlanTodo?.length} */}
                        {item.carePlanTodo &&
                          item.carePlanTodo.map((days, i) => (
                            <div key={days.id} style={{ width: "60px" }}>
                              {index === 0 && (
                                <div className="text-bold p-1 border">Day {i + 1}</div>
                              )}

                              <div className="p-1 border text-center" style={{ width: "60px" }}>
                                {days.checked ? "x" : "-"}
                              </div>
                            </div>
                          ))}
                      </div>
                    </div>
                  ))}
              </div>
            </div>
          </div>
        </Modal.Body>
      </Modal>
    </>
  );
};
export default CarePlanViewToDo;
