import React, { useState, useEffect, useMemo } from "react";

const DataTable = ({ data }) => {
  const [pageLimit, setPageLimit] = useState(10);
  const [pageNumber, setPageNumber] = useState(1);
  const [pageData, setPageData] = useState([]);

  //   const totalPages = useMemo(() => {
  //     return Math.ceil(data.length / pageLimit);
  //   }, [data, pageLimit]);

  console.log("data in data table", data);
  return (
    <div className="card-body">
      <div className="table-responsive">
        {/* <input
        className="search-field"
        placeholder="Type a name to filter ..."
        ref={input => (this.search = input)}
        onChange={this.handleInputChange}
      /> */}

        <table className="table table-bordered" id="dataTable" width="100%" cellSpacing={0}>
          <thead>
            {/* <tr>{ThData()}</tr> */}
            <tr>
              <th>userId </th>
              <th>title</th>
              <th>completed</th>
            </tr>
          </thead>
          <tbody>
            {/* {tdData()} */}

            {/* {data.map((d) => (
              <tr key={data.id}>
                <td>{d.id}</td>
                <td>{d.userId}</td>
                <td>{d.title}</td>
                <td>
                  <input type="checkbox" checked={d.completed} />
                </td>
              </tr>
            ))} */}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default DataTable;
