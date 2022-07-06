import React, { useState, useEffect, useCallback, useMemo } from "react";
import axios from "axios";
import DataTable from "react-data-table-component";
import { useSelector } from "react-redux";
import moment from "moment";
import { Form } from "react-bootstrap";
import API from "../../util/apiService";
import CalyxLoader from "../../components/commons/CalyxLoader";

import CarePlanModal from "./modal/CarePlanModal";
import CarePlanViewToDo from "./modal/CarePlanViewToDo";
import CarePlanView from "./modal/CarePlanView";
// import EnrollmentViewModal from "../patientEnrollment/modal/EnrollmentViewModal";
import EnrollmentViewModal from "./modal/EnrollmentViewModal";

const CarePlan = () => {
  const statusList = [
    {
      label: "All",
      val: "ALL",
    },
    {
      label: "PENDING",
      val: "PENDING",
    },
    {
      label: "DRAFT",
      val: "DRAFT",
    },
    {
      label: "PENDING APPROVAL",
      val: "PENDING_APPROVAL",
    },
    {
      label: "APPROVED",
      val: "APPROVED",
    },
    {
      label: "IN PROGRESS",
      val: "IN_PROGRESS",
    },

    // {
    //   label: "DEVELOP",
    //   val: "DEVELOP",
    // },
    // {
    //   label: "EDIT",
    //   val: "EDIT",
    // },
    // {
    //   label: "COMPLETE",
    //   val: "COMPLETE",
    // },
  ];

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [showViewToDo, setShowViewToDo] = useState(false);
  const [showView, setShowView] = useState(false);
  const [openView, setOpenView] = useState(false);

  const [tableData, setTableData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [totalRows, setTotalRows] = useState(0);
  const [perPage, setPerPage] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusVal, setStatusVal] = useState("");
  // const [isSubmitted, setIsSubmitted] = useState(false);

  const { user } = useSelector((state) => state.auth);

  const [rowData, setRowData] = useState({});

  const getPatientList = async (page, size = perPage, search, status) => {
    setLoading(true);

    const { data } = await API.get(
      `/careplan/api/v1.1/careplans?pageSize=${size}&pageNo=${page}&query=${search}&status=${status}`,
    );

    setTableData(data.records);
    setTotalRows(data.totalCount);
    setLoading(false);
  };

  // const getPatientList = useCallback((page, size = perPage, search, status) => async () => {
  //   setLoading(true);
  //   const { data } = await axios.get(
  //     `http://localhost:9006/api/v1.1/careplans/query?${search}&status=${status}&pageNo=${page}&pageSize=${size}`,
  //   );

  //   setTableData(data);
  //   setTotalRows(data.totalCount);
  //   setLoading(false);
  // });

  useEffect(() => {
    getPatientList(currentPage, perPage, searchTerm, statusVal);
  }, [showViewToDo]);

  // useEffect(() => {
  //   console.log("api will call here", isSubmitted);
  // }, [isSubmitted]);

  const isSubmitted = (isFlag) => {
    setShowViewToDo(isFlag);
  };

  // const searchHandler = (e) => {
  //   e.preventDefault();
  //   if (e.target.value.length > 2) {
  //     setSearchTerm(e.target.value);
  //     getPatientList(currentPage, perPage, searchTerm, statusVal);
  //   }
  // };

  const searchHandler = (e) => {
    e.preventDefault();
    if (e.target.value.length > 2) {
      // setSearchTerm(e.target.value);
      getPatientList(currentPage, perPage, searchTerm, statusVal);
    } else if (e.target.value.length === 0) {
      setSearchTerm("");
      getPatientList(currentPage, perPage, "", statusVal);
    }
  };

  const handleSearch = (e) => {
    e.preventDefault();
    getPatientList(currentPage, perPage, searchTerm, statusVal);
  };

  const clearSearch = (e) => {
    e.preventDefault();
    setSearchTerm("");
    getPatientList(currentPage, perPage, "", statusVal);
  };

  const statusHandler = (data) => {
    setStatusVal(data);
    getPatientList(currentPage, perPage, searchTerm, data);
  };

  /* Pagination */
  const handlePageChange = (page) => {
    // getPatientList(page, perPage, searchTerm, statusVal);
    setCurrentPage(page);
  };

  const handlePerRowsChange = async (newPerPage, page) => {
    // getPatientList(page, newPerPage, searchTerm, statusVal);
    setPerPage(newPerPage);
  };

  /* Column start here */
  const handleActions = useCallback((row) => async () => {
    setRowData(row);
    setIsModalOpen(!isModalOpen);
  });

  const handleView = useCallback((row) => async () => {
    setRowData(row);
    setShowView(!showView);
  });

  const handleViewEnrollment = useCallback((row) => async () => {
    setRowData(row);
    setOpenView(!openView);
  });

  const handleViewTodo = useCallback((row) => async () => {
    setRowData(row);
    // console.log("to do call");
    setShowViewToDo(true);
  });

  const handleActionBtn = (row) => {
    switch (row.status) {
      case "PENDING":
        return (
          <>
            {user.currentRole === "ROLE_CARE_MANAGER" ? (
              <button type="button" className="btn btn-link p-0" onClick={handleActions(row)}>
                Develop
              </button>
            ) : (
              <>-</>
            )}
          </>
        );

      case "DRAFT":
        return (
          <>
            {user.currentRole === "ROLE_CARE_MANAGER" ? (
              <button type="button" className="btn btn-link p-0" onClick={handleActions(row)}>
                Edit
              </button>
            ) : (
              <>-</>
            )}
          </>
        );

      case "PENDING_APPROVAL":
        return (
          <>
            {user.currentRole === "ROLE_ADMIN" ? (
              <button type="button" className="btn btn-link p-0" onClick={handleActions(row)}>
                Approve
              </button>
            ) : (
              <>-</>
            )}
          </>
        );

      case "APPROVED":
        return (
          <>
            {user.currentRole === "ROLE_CARE_MANAGER" ? (
              <button type="button" className="btn btn-link p-0" onClick={handleViewTodo(row)}>
                Task List
              </button>
            ) : (
              <>-</>
            )}
          </>
        );

      default:
        return true;
    }
  };

  const columns = useMemo(() => [
    {
      name: "Enrollment Id",
      // selector: (row) => `${row.first_name}`,
      cell: (row) => (
        <button type="button" className="btn btn-link p-0" onClick={handleViewEnrollment(row)}>
          {row.entrollmentId}
        </button>
      ),
      // sortable: true,
      center: true,
    },
    {
      name: "Enrollment Date",
      selector: (row) => `${moment(row.entrollmentDate).format("MM/DD/YYYY")}`,
      sortable: true,
      center: true,
    },
    {
      name: "MR No",
      selector: (row) => `${row.patinentMrn}`,
      sortable: true,
      center: true,
    },
    {
      name: "Patient Name",
      selector: (row) => `${row.patinentName}`,
      sortable: true,
      center: true,
    },
    {
      name: "Gender",
      selector: (row) => `${row.patinentGender}`,
      sortable: true,
      center: true,
    },
    {
      name: "Age",
      selector: (row) => `${row.age}`,
      // sortable: true,
      width: "40px",
      center: true,
    },
    {
      name: "Plan Date",
      selector: (row) => `${moment(row.startDate).format("MM/DD/YYYY")}`,
      // sortable: true,
      // width: "40px",
      center: true,
    },
    {
      name: "Plan Status",

      cell: (row) => (
        <>
          {row.status === "APPROVED" ? (
            <button type="button" className="btn btn-link p-0" onClick={handleView(row)}>
              {row.status}
            </button>
          ) : (
            <span>{row.status === "PENDING_APPROVAL" ? "PENDING APPROVAL" : row.status}</span>

            // <span>{row.status}</span>
          )}
        </>
      ),
      // sortable: true,
      center: true,
    },
    {
      name: "Actions",
      // sortable: true,
      cell: (row) => handleActionBtn(row),
      center: true,
    },
    {
      name: "Admission No",
      selector: (row) => `${row.admissionNo}`,
      sortable: true,
      center: true,
    },
  ]);

  return (
    <>
      {loading && <CalyxLoader />}
      <h1 className="h3 mb-3">Patient List</h1>
      <div className="row">
        <div className="col-12">
          <div className="card">
            <div className="card-header">
              <div className="row">
                <div className="col-5">
                  <form onSubmit={handleSearch}>
                    <div className="input-group input-group-navbar">
                      <input
                        className="form-control"
                        placeholder="Search ..."
                        name="search"
                        id="search"
                        autoComplete="off"
                        type="text"
                        value={searchTerm}
                        onChange={(e) => {
                          searchHandler(e);
                          setSearchTerm(e.target.value);
                        }}
                      />
                      <button className="btn px-2" type="submit">
                        <i className="bi bi-search" />
                      </button>
                      {searchTerm && (
                        <button className="btn px-2" type="button" onClick={clearSearch}>
                          <i className="bi bi-x" />
                        </button>
                      )}
                    </div>
                  </form>
                </div>
                <div className="col-4" />
                <div className="col-3">
                  <div className="form-group row">
                    <label htmlFor="inputEmail3" className="col-sm-5 col-form-label">
                      Status
                    </label>
                    <div className="col-sm-7">
                      {/* <Form.Select size="sm" onChange={(e) => statusHandler(e)}>
                        {statusList &&
                          statusList.map((item) => (
                            <option key={item.val} value={item.val}>
                              {item.label}
                            </option>
                          ))}
                      </Form.Select> */}

                      <Form.Select size="sm" onChange={(e) => statusHandler(e.target.value)}>
                        {statusList &&
                          statusList.map((item) => (
                            <option key={item.val} value={item.val}>
                              {item.label}
                            </option>
                          ))}
                      </Form.Select>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            {/* /.card-header */}
            <div className="card-body calyx-table">
              <DataTable
                // title="Patient List"
                columns={columns}
                data={tableData}
                progressPending={loading}
                pagination
                paginationServer
                paginationTotalRows={totalRows}
                paginationDefaultPage={currentPage}
                onChangeRowsPerPage={handlePerRowsChange}
                onChangePage={handlePageChange}
                // selectableRows
                // onSelectedRowsChange={({ selectedRows }) => console.log(selectedRows)}
              />
            </div>
            {/* /.card-body */}
          </div>
        </div>
      </div>

      {isModalOpen && (
        <CarePlanModal
          isOpen={isModalOpen}
          handleClick={() => setIsModalOpen(!isModalOpen)}
          patient={rowData}
          isSubmitted={isSubmitted}
        />
      )}

      {showViewToDo && (
        <CarePlanViewToDo
          isOpen={showViewToDo}
          handleClick={() => setShowViewToDo(!showViewToDo)}
          patient={rowData}
        />
      )}

      {showView && (
        <CarePlanView
          isOpen={showView}
          handleClick={() => setShowView(!showView)}
          patient={rowData}
        />
      )}

      {openView && (
        <EnrollmentViewModal
          handleClick={() => setOpenView(!openView)}
          isOpen={openView}
          patient={rowData}
          // action={isAssigned}
          role={user.currentRole}
        />
      )}
    </>
  );
};

export default CarePlan;
