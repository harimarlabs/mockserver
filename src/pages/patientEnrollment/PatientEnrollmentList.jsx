import React, { useState, useEffect, useCallback, useMemo } from "react";
import axios from "axios";
import DataTable from "react-data-table-component";
import { useSelector } from "react-redux";
import moment from "moment";
import { Form } from "react-bootstrap";
import Select from "react-select";

import API from "../../util/apiService";
import EnrollmentViewModal from "./modal/EnrollmentViewModal";
import EnrollmentEditModal from "./modal/EnrollmentEditModal";
import EnrollmentApproveModal from "./modal/EnrollmentApproveModal";
import CalyxLoader from "../../components/commons/CalyxLoader";
import RiskScore from "./modal/RIskScore";

const PatientEnrollmentList = () => {
  const { isAuthenticated, user } = useSelector((state) => state.auth);

  const statusList = [
    {
      label: "All",
      val: "",
    },
    {
      label: "New",
      val: "New",
    },
    {
      label: "Assigned",
      val: "Assigned",
    },
    {
      label: "PendingApproval",
      val: "PendingApproval",
    },
  ];

  const [tableData, setTableData] = useState([]);
  const [loading, setLoading] = useState(false);

  const [totalRows, setTotalRows] = useState(0);
  const [perPage, setPerPage] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusVal, setStatusVal] = useState("");

  const [isCalculate, setIsCalculate] = useState(false);
  const [openView, setOpenView] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [isApprove, setIsApprove] = useState(false);
  const [openCareManager, setOpenCareManager] = useState(false);
  const [isAssigned, setIsAssigned] = useState(false);

  const [clinicalData, setClinicalData] = useState({});
  const [rowData, setRowData] = useState({});

  const getPatientList = async (page, size = perPage, search, status) => {
    const searchParam = `mrNumber=${search}&name=${search}&enrollmentId=${search}`;
    setLoading(true);

    // console.log("user", user.currentRole);
    // console.log("search, status", search, status);
    // const { data } = await axios.get(
    //   `http://localhost:9008/api/v1.0/patients/search?${searchParam}&status=${status}&pageNo=${page}&pageSize=${size}`,
    // );

    const { data } = await API.get(
      `/patientenrollment/api/v1.0/patients/search?${searchParam}&status=${status}&pageNo=${page}&pageSize=${size}`,
    );

    setTableData(data.data);
    setTotalRows(data.totalCount);
    setLoading(false);
  };

  useEffect(() => {
    getPatientList(currentPage, perPage, searchTerm, statusVal);
  }, [isCalculate, openView]);

  // useEffect(() => {
  //   const delayDebounceFn = setTimeout(() => {
  //     console.log(searchTerm);
  //     // Send Axios request here
  //   }, 1000);

  //   return () => clearTimeout(delayDebounceFn);
  // }, [searchTerm]);

  const riskScoreOpen = (data) => {
    setClinicalData(data);
    setIsCalculate(!isCalculate);
  };

  const searchHandler = (e) => {
    // console.log("searchTerm====", searchTerm);
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

  /* Table Section start here */

  const handleView = useCallback((row) => async () => {
    setRowData(row);
    setOpenView(!openView);
    setIsAssigned(false);
  });

  const handleAssign = useCallback(
    (row) => async () => {
      setRowData(row);
      setOpenView(!openView);
      setIsAssigned(true);
    },
    // [currentPage, perPage, totalRows],
  );

  const handleChange = useCallback(
    (row) => async () => {
      setRowData(row);
      setIsEdit(!isEdit);
      // setIsCalculate(!isCalculate);
    },
    // [currentPage, perPage, totalRows],
  );

  const handleApprove = useCallback((row) => async () => {
    // console.log("Approve", row);
    setRowData(row);
    setIsApprove(!isApprove);
  });

  const handlePageChange = (page) => {
    // getPatientList(page);
    getPatientList(page, perPage, searchTerm, statusVal);
    setCurrentPage(page);
  };

  const handlePerRowsChange = async (newPerPage, page) => {
    // getPatientList(page, newPerPage);
    getPatientList(page, newPerPage, searchTerm, statusVal);
    setPerPage(newPerPage);
  };

  const handleActionBtn = (row) => {
    switch (row.status) {
      case "New":
        return (
          <>
            &nbsp;
            <button type="button" className="btn btn-link p-0" onClick={handleAssign(row)}>
              Assign
            </button>
          </>
        );

      case "Assigned":
        return (
          <>
            {user.currentRole === "ROLE_ADMIN" ? (
              <button type="button" className="btn btn-link p-0" onClick={handleAssign(row)}>
                Re-assign
              </button>
            ) : (
              <button type="button" className="btn btn-link p-0" onClick={handleChange(row)}>
                Change
              </button>
            )}
          </>
        );

      case "PendingApproval":
        return (
          <>
            {user.currentRole === "ROLE_ADMIN" && (
              <button type="button" className="btn btn-link p-0" onClick={handleApprove(row)}>
                Approve
              </button>
            )}
          </>
        );

      default:
        return true;
    }
  };

  const columns = useMemo(
    () => [
      {
        name: "Enrollment Id",
        // selector: (row) => `${row.first_name}`,
        cell: (row) => (
          <button type="button" className="btn btn-link p-0" onClick={handleView(row)}>
            {row.enrollmentId}
          </button>
        ),
        // sortable: true,
        center: true,
      },
      {
        name: "Enrollment Date",
        selector: (row) => `${moment(row.enrollmentDate).format("MM/DD/YYYY")}`,
        sortable: true,
        center: true,
      },
      {
        name: "MR No",
        selector: (row) => `${row.mrNumber}`,
        sortable: true,
        center: true,
      },
      {
        name: "Patient Name",
        selector: (row) => `${row.name}`,
        sortable: true,
        center: true,
      },
      {
        name: "Gender",
        selector: (row) => `${row.gender}`,
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
        name: "Status",
        selector: (row) => `${row.status}`,
        sortable: true,
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
    ],
    // [handleAssign, handleView, handleApprove],
  );

  return (
    <>
      {/* <TableSearh /> */}
      {/* <DataTable data={data} /> */}
      {loading && <CalyxLoader />}
      <h1 className="h3 mb-3">Patient List</h1>
      <div className="row">
        <div className="col-12">
          <div className="card">
            <div className="card-header">
              <div className="row">
                {/* <div className="col-3">
                  <h3 className="card-title">Patient List</h3>
                </div> */}
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
      {/* <button type="button" onClick={handleModalClick}>
        {" "}
        Open Modal{" "}
      </button> */}
      {openView && (
        <EnrollmentViewModal
          handleClick={() => setOpenView(!openView)}
          isOpen={openView}
          patient={rowData}
          action={isAssigned}
          role={user.currentRole}
        />
      )}

      {isEdit && (
        <EnrollmentEditModal
          handleClick={() => setIsEdit(!isEdit)}
          isOpen={isEdit}
          patient={rowData}
          clinicalInfo={riskScoreOpen}
        />
      )}

      {isApprove && (
        <EnrollmentApproveModal
          handleClick={() => setIsApprove(!isApprove)}
          isOpen={isApprove}
          patient={rowData}
        />
      )}

      {isCalculate && (
        <RiskScore
          handleClick={() => setIsCalculate(!isCalculate)}
          isOpen={isCalculate}
          patient={rowData}
          clinicalData={clinicalData}
        />
      )}
    </>
  );
};

export default PatientEnrollmentList;
