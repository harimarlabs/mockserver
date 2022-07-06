import React from "react";

const Table = () => {


    const startinIndex = (props.currentPage - 1) * props.itemsPerPage;
  const lastIndex = startinIndex + props.itemsPerPage;

  const pageData = props.data.slice(startinIndex, lastIndex);
  return pageData.map((item, index) => {
    const { _id, name, type, company } = item; //destructuring
    return (
      <tr key={index}>
        <td className="cell id">{_id}</td>
        <td className="cell name">{name}</td>
        <td className="cell type">{type}</td>
        <td className="cell company">{company}</td>
      </tr>
    );
  });
};




  return (<div>Table</div>);
};

export default Table;
