import { useState } from "react";

export default function App(){
  const [form, setForm] = useState({
    name: undefined,
    surname: undefined,
    lastname: undefined,
    age: 0,
    sex: 0
  }); 

  const handleChange = (event) => {
    const { target: { name, value } } = event;
    
    setForm((previous)=>{
      console.log(previous);

      return ({
        ...previous,
        [name]: value
      });
    });
  }

  return (<div>
    <div className="m-4 card col-4">
      <div className="card-body">
        <form className="row g-3">
          
          <div className="col-12">
            <label htmlFor="name">Nombre(s)</label>
            <input value={form.name} onChange={(event)=> handleChange(event)} type="text" name="name" id="name" className="form-control"/>
          </div>

          <div className="col-6">
            <label htmlFor="surname">Apellido paterno</label>
            <input value={form.surname} onChange={(event)=> handleChange(event)} type="text" name="surname" id="surname" className="form-control"/>
          </div>
          <div className="col-6">
            <label htmlFor="lastname">Apellido materno</label>
            <input value={form.lastname} onChange={(event)=> handleChange(event)} type="text" name="lastname" id="lastname" className="form-control"/>
          </div>

          <div className="col-6">
            <label htmlFor="age">Edad</label>
            <input value={form.age} onChange={(event)=> handleChange(event)} type="number" name="age" id="age" className="form-control"/>
          </div>
          <div className="col-6">
            <label htmlFor="sex">Sexo</label>
            <select value={form.sex} onChange={(event)=> handleChange(event)} name="sex" id="sex" className="form-select">
              <option value="0">Masculino</option>
              <option value="1">Femenino</option>
            </select>
          </div>

        </form>
      </div>
    </div>
  </div>);
}