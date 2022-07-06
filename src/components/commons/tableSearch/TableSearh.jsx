import React from "react";

const data = [
  {
    _id: "5c9e17581b2804c21c89f7b7",
    name: "CAXT",
    type: "SMART TRIGGER EMAIL",
    company: "AUTOGRATE",
    action: ["Add", "Assign"],
  },
  {
    _id: "5c9e175817493f1361a22519",
    name: "UNEEQ",
    type: "SMS CONNECTOR",
    company: "VURBO",
  },
  {
    _id: "5c9e1758afa78406b10414d6",
    name: "JIMBIES",
    type: "PUSH EMAIL",
    company: "PANZENT",
  },
  {
    _id: "5c9e1758389a61d6709ee2eb",
    name: "ETERNIS",
    type: "PUSH EMAIL",
    company: "ZORROMOP",
  },
  {
    _id: "5c9e1758ce8c60cd36c93bd6",
    name: "CINESANCT",
    type: "PUSH EMAIL",
    company: "GENMEX",
  },
  {
    _id: "5c9e1758df67f2b42fc900eb",
    name: "PEARLESEX",
    type: "GENERAL EMAIL",
    company: "LIQUICOM",
  },
  {
    _id: "5c9e175886ce38acfb323e7c",
    name: "AUSTECH",
    type: "SMS CONNECTOR",
    company: "GROK",
  },
  {
    _id: "5c9e17586c3f18b337165ee0",
    name: "KROG",
    type: "SMART TRIGGER PUSH",
    company: "ONTAGENE",
  },
  {
    _id: "5c9e1758fe2fbbb001921473",
    name: "VIRXO",
    type: "SMART TRIGGER EMAIL",
    company: "MONDICIL",
  },
  {
    _id: "5c9e1758fe61db8d481c2c3c",
    name: "CYTREK",
    type: "SMART TRIGGER EMAIL",
    company: "GRONK",
  },
  {
    _id: "5c9e175853aa20f34490bcef",
    name: "QUARMONY",
    type: "SMART TRIGGER PUSH",
    company: "RECRITUBE",
  },
  {
    _id: "5c9e17583df99715bde886a5",
    name: "WAAB",
    type: "SMART TRIGGER PUSH",
    company: "SUNCLIPSE",
  },
  {
    _id: "5c9e1758a70efd94b9c32e31",
    name: "NAMEBOX",
    type: "SMS CONNECTOR",
    company: "IMMUNICS",
  },
  {
    _id: "5c9e1758324e2a995015e41c",
    name: "RODEMCO",
    type: "GENERAL EMAIL",
    company: "MOREGANIC",
  },
  {
    _id: "5c9e175827b25ab774c2b5b9",
    name: "STRALOY",
    type: "SMART TRIGGER PUSH",
    company: "TUBESYS",
  },
  {
    _id: "5c9e17586b3ed54ea0fe712f",
    name: "MATRIXITY",
    type: "CONNECTOR",
    company: "DYNO",
  },
  {
    _id: "5c9e1758e8cefaac38040adc",
    name: "FLOTONIC",
    type: "CONNECTOR",
    company: "DIGIGENE",
  },
];

const TableSearh = () => {
  const initialState = {
    query: "",
    results: data,
    displayData: data,
    itemsPerPage: 10,
    currentPage: 1,
  };

  //   const column = Object.keys(data[0]);
  const column = ["name", "type", "company", "action"];

  const ThData = () => {
    return column.map((item) => {
      return <th key={item}>{item}</th>;
    });
  };

  const tdData = () => {
    return data.map((item) => {
      return (
        <tr key={item}>
          {column.map((v) => {
            return <td key={item[v]}>{item[v]}</td>;
          })}
        </tr>
      );
    });
  };

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
            <tr>{ThData()}</tr>
          </thead>
          <tbody>
            {/* <Table
          data={this.state.displayData}
          itemsPerPage={this.state.itemsPerPage}
          currentPage={this.state.currentPage}
        /> */}
            {tdData()}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default TableSearh;
