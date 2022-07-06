import React, { useState, useEffect, useCallback, useMemo } from "react";
import axios from "axios";
import DataTable from "react-data-table-component";

const AdvancedPaginationTable = ({ title, columns, data = [], loading = false }) => {
  // const [data, setData] = useState([]);
  // const [loading, setLoading] = useState(false);
  const [totalRows, setTotalRows] = useState(0);
  const [perPage, setPerPage] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);
  // const [deleted, setDeleted] = useState([]);

  const fetchUsers = async (page, size = perPage) => {
    setLoading(true);

    const response = await axios.get(
      `https://reqres.in/api/users?page=${page}&per_page=${size}&delay=1`,
    );

    // setData(response.data.data);
    setTotalRows(response.data.total);
    // setLoading(false);
  };

  useEffect(() => {
    fetchUsers(1);
  }, []);

  const handleAssign = useCallback(
    (row) => async () => {
      console.log("row data in delete", row);

      return false;

      // await axios.delete(`https://reqres.in/api/users/${row.id}`);
      // const response = await axios.get(
      //   `https://reqres.in/api/users?page=${currentPage}&per_page=${perPage}`
      // );

      // setData(removeItem(response.data.data, row));
      // setTotalRows(totalRows - 1);
    },
    [currentPage, perPage, totalRows],
  );

  const handleView = useCallback((row) => async () => {
    console.log("row data in eidt", row);
  });

  const handleApprove = useCallback((row) => async () => {
    console.log("Approve", row);
  });

  // const columns = useMemo(
  //   () => [
  //     {
  //       name: "First Name",
  //       selector: (row) => `${row.first_name}`,
  //       sortable: true,
  //     },
  //     {
  //       name: "Last Name",
  //       selector: (row) => `${row.last_name}`,
  //       sortable: true,
  //     },
  //     {
  //       name: "Email",
  //       selector: (row) => `${row.email}`,
  //       sortable: true,
  //     },
  //     {
  //       name: "Actions",
  //       cell: (row) => (
  //         <>
  //           <button type="button" className="btn btn-link p-0" onClick={handleAssign(row)}>
  //             Assign
  //           </button>
  //           &nbsp;
  //           <button type="button" className="btn btn-link p-0" onClick={handleView(row)}>
  //             View
  //           </button>
  //           &nbsp;
  //           <button type="button" className="btn btn-link p-0" onClick={handleApprove(row)}>
  //             Approve
  //           </button>
  //         </>
  //       ),
  //     },
  //   ],
  //   [handleAssign, handleView, handleApprove],
  // );

  const handlePageChange = (page) => {
    fetchUsers(page);
    setCurrentPage(page);
  };

  const handlePerRowsChange = async (newPerPage, page) => {
    fetchUsers(page, newPerPage);
    setPerPage(newPerPage);
  };

  return (
    <>
      <div className="card shadow mb-4">
        <div className="card-header py-3">
          <div className="row">
            <div className="col-3 align-self-start">
              <h6 className="m-0 font-weight-bold text-primary">{title}</h6>
            </div>

            <div className="col-5">
              <form className="navbar-form" role="search">
                <div className="input-group-sm add-on">
                  {/* <input
                    className="form-control"
                    placeholder="Search ..."
                    name="search"
                    id="search"
                    autoComplete="off"
                    type="text"
                    onChange={(e) => setSearchTerm(e.target.value)}
                  /> */}
                </div>
              </form>
            </div>
          </div>
        </div>

        <DataTable
          // title="Patient List"
          columns={columns}
          data={data}
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
    </>
  );
};

export default AdvancedPaginationTable;
