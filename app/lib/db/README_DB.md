____________________________________________
profile structure:
    id --> integer AUTOINCREMENTED
    name --> text not null
    donor --> text not null
    dob --> text not null
    bloodtype --> text not null
    sex --> text not null
____________________________________________
create new profile:
    createprof(profile 'model')

read profile:
    readprofile()

delete profile:
    deleteprof(int id)
____________________________________________
cabinet structure:
    id --> integer AUTOINCREMENTED
    name --> text not null
    dosage --> text not null
    time --> time not null
    currstock --> int not null
    initstock --> int not null
    priority --> int not null
    category --> text not null (default 'tablet')
    unit --> text not null (default 'pills')
____________________________________________
create new medicine:
    createmed(cabinet 'model')

reads all medicines:
    readAllMedicines()

____________________________________________
intake structure:
    cabinetid --> (refrences med id)
    name --> (refrences med name)
    ttime --> (target time to take medicine) time not null (refrences time of medicine in cabinet)
    time --> (time of when it was actually taken) time not null
    date --> text not null
    stock --> int not null (refrences currstock)
____________________________________________
create new log:
    createlog(intake 'model')

read log:
    readintakelog()