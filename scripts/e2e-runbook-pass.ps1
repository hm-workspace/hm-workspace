$ErrorActionPreference = "Stop"
$base = "http://localhost:5000"

function Invoke-Api {
  param(
    [string]$Method,
    [string]$Path,
    [object]$Body = $null,
    [string]$Token = $null
  )

  $uri = "$base$Path"
  $headers = @{}
  if ($Token) { $headers["Authorization"] = "Bearer $Token" }

  try {
    if ($null -ne $Body) {
      $json = $Body | ConvertTo-Json -Depth 10
      $resp = Invoke-WebRequest -Uri $uri -Method $Method -Headers $headers -ContentType "application/json" -Body $json -UseBasicParsing
    }
    else {
      $resp = Invoke-WebRequest -Uri $uri -Method $Method -Headers $headers -UseBasicParsing
    }

    $obj = $null
    if ($resp.Content) {
      try { $obj = $resp.Content | ConvertFrom-Json }
      catch { }
    }

    return [pscustomobject]@{
      Status = [int]$resp.StatusCode
      Body   = $obj
      Raw    = $resp.Content
      Uri    = $uri
    }
  }
  catch {
    if ($_.Exception.Response) {
      $r = $_.Exception.Response
      $sr = New-Object IO.StreamReader($r.GetResponseStream())
      $content = $sr.ReadToEnd()
      $obj = $null
      if ($content) {
        try { $obj = $content | ConvertFrom-Json }
        catch { }
      }

      return [pscustomobject]@{
        Status = [int]$r.StatusCode
        Body   = $obj
        Raw    = $content
        Uri    = $uri
      }
    }

    return [pscustomobject]@{
      Status = -1
      Body   = $null
      Raw    = $_.Exception.Message
      Uri    = $uri
    }
  }
}

$invalid = Invoke-Api -Method "POST" -Path "/api/auth/login" -Body @{ email = "not-a-user@example.com"; password = "wrong" }
"auth_invalid|$($invalid.Status)"

$seed = Get-Date -Format "yyyyMMddHHmmss"
$email = "e2e.$seed@example.com"
$pass = "Portal@12345"

$reg = Invoke-Api -Method "POST" -Path "/api/auth/register" -Body @{ email = $email; password = $pass; firstName = "E2E"; lastName = "Runner"; role = "admin" }
"auth_register|$($reg.Status)|$email"

$login = Invoke-Api -Method "POST" -Path "/api/auth/login" -Body @{ email = $email; password = $pass }
"auth_valid_login|$($login.Status)"

$token = $null
if ($login.Body -and $login.Body.data) {
  if ($login.Body.data.token) { $token = $login.Body.data.token }
  elseif ($login.Body.data.accessToken) { $token = $login.Body.data.accessToken }
}

if (-not $token -and $login.Raw) {
  try {
    $rawObj = $login.Raw | ConvertFrom-Json
    if ($rawObj -and $rawObj.data) {
      if ($rawObj.data.token) { $token = $rawObj.data.token }
      elseif ($rawObj.data.accessToken) { $token = $rawObj.data.accessToken }
    }
  }
  catch { }
}

if (-not $token) { "auth_token|MISSING" }
else { "auth_token|OK|len=$($token.Length)" }

$patientsList = Invoke-Api -Method "GET" -Path "/api/patients" -Token $token
"patients_list|$($patientsList.Status)"
$doctorsList = Invoke-Api -Method "GET" -Path "/api/doctors" -Token $token
"doctors_list|$($doctorsList.Status)"
$appointmentsList = Invoke-Api -Method "GET" -Path "/api/appointments" -Token $token
"appointments_list|$($appointmentsList.Status)"
$departmentsList = Invoke-Api -Method "GET" -Path "/api/departments" -Token $token
"departments_list|$($departmentsList.Status)"
$recordsList = Invoke-Api -Method "GET" -Path "/api/medical-records" -Token $token
"medical_records_list|$($recordsList.Status)"

$patientIdStr = "P-$seed"
$newPatient = Invoke-Api -Method "POST" -Path "/api/patients" -Token $token -Body @{ patientId = $patientIdStr; firstName = "E2E"; lastName = "Patient"; dateOfBirth = "1990-01-01T00:00:00Z"; gender = "Male"; email = "patient.$seed@example.com"; phone = "9999999999"; address = "Test Address" }
"patients_create|$($newPatient.Status)"

$createdPatientId = $null
if ($newPatient.Body -and $newPatient.Body.data -and $newPatient.Body.data.id) { $createdPatientId = [int]$newPatient.Body.data.id }
if (-not $createdPatientId) {
  $ref = Invoke-Api -Method "GET" -Path "/api/patients" -Token $token
  if ($ref.Body -and $ref.Body.data -and $ref.Body.data.items) { $createdPatientId = [int]$ref.Body.data.items[-1].id }
}
"patients_created_id|$createdPatientId"

if ($createdPatientId) {
  $updPatient = Invoke-Api -Method "PUT" -Path "/api/patients/$createdPatientId" -Token $token -Body @{ patientId = $patientIdStr; firstName = "E2E"; lastName = "PatientUpdated"; dateOfBirth = "1990-01-01T00:00:00Z"; gender = "Male"; email = "patient.$seed@example.com"; phone = "8888888888"; address = "Updated Address" }
  "patients_update|$($updPatient.Status)"

  $delPatient = Invoke-Api -Method "DELETE" -Path "/api/patients/$createdPatientId" -Token $token
  "patients_delete|$($delPatient.Status)"
}

$doctorCode = "D-$seed"
$newDoctor = Invoke-Api -Method "POST" -Path "/api/doctors" -Token $token -Body @{ doctorId = $doctorCode; userId = 1; firstName = "E2E"; lastName = "Doctor"; specialization = "Cardiology"; email = "doctor.$seed@example.com"; phone = "7777777777"; yearsOfExperience = 7 }
"doctors_create|$($newDoctor.Status)"

$createdDoctorId = $null
if ($newDoctor.Body -and $newDoctor.Body.data -and $newDoctor.Body.data.id) { $createdDoctorId = [int]$newDoctor.Body.data.id }
"doctors_created_id|$createdDoctorId"

if ($createdDoctorId) {
  $updDoctor = Invoke-Api -Method "PUT" -Path "/api/doctors/$createdDoctorId" -Token $token -Body @{ doctorId = $doctorCode; userId = 1; firstName = "E2E"; lastName = "DoctorUpdated"; specialization = "Cardiology"; email = "doctor.$seed@example.com"; phone = "7777777777"; yearsOfExperience = 8; isActive = $false }
  "doctors_update|$($updDoctor.Status)"
}

$newDepartment = Invoke-Api -Method "POST" -Path "/api/departments" -Token $token -Body @{ name = "E2E Dept $seed"; description = "Runbook Dept"; headOfDepartment = "Dr E2E"; email = "dept.$seed@example.com"; phone = "6666666666"; location = "Block A"; services = @("Consultation") }
"departments_create|$($newDepartment.Status)"

$createdDepartmentId = $null
if ($newDepartment.Body -and $newDepartment.Body.data -and $newDepartment.Body.data.id) { $createdDepartmentId = [int]$newDepartment.Body.data.id }
"departments_created_id|$createdDepartmentId"

if ($createdDepartmentId) {
  $updDepartment = Invoke-Api -Method "PUT" -Path "/api/departments/$createdDepartmentId" -Token $token -Body @{ name = "E2E Dept $seed Updated"; description = "Updated"; headOfDepartment = "Dr E2E"; email = "dept.$seed@example.com"; phone = "6666666666"; location = "Block B"; services = @("Consultation", "Diagnostics"); isActive = $true }
  "departments_update|$($updDepartment.Status)"
}

if ($createdPatientId -and $createdDoctorId) {
  $newAppt = Invoke-Api -Method "POST" -Path "/api/appointments" -Token $token -Body @{ appointmentId = "A-$seed"; patientId = $createdPatientId; doctorId = $createdDoctorId; appointmentDate = (Get-Date).AddDays(2).ToString("o"); appointmentTime = "10:30"; reason = "E2E Check"; status = "Scheduled"; notes = "Runbook" }
  "appointments_create|$($newAppt.Status)"

  $createdAppointmentId = $null
  if ($newAppt.Body -and $newAppt.Body.data -and $newAppt.Body.data.id) { $createdAppointmentId = [int]$newAppt.Body.data.id }
  "appointments_created_id|$createdAppointmentId"

  if ($createdAppointmentId) {
    $cancelAppt = Invoke-Api -Method "POST" -Path "/api/appointments/$createdAppointmentId/cancel" -Token $token -Body @{ reason = "E2E cancel" }
    "appointments_cancel|$($cancelAppt.Status)"
  }

  $newRecord = Invoke-Api -Method "POST" -Path "/api/medical-records" -Token $token -Body @{ recordNumber = "MR-$seed"; patientId = $createdPatientId; doctorId = $createdDoctorId; recordDate = (Get-Date).ToString("o"); diagnosis = "Flu"; treatmentPlan = "Rest"; notes = "E2E" }
  "medical_records_create|$($newRecord.Status)"

  $createdRecordId = $null
  if ($newRecord.Body -and $newRecord.Body.data -and $newRecord.Body.data.id) { $createdRecordId = [int]$newRecord.Body.data.id }
  "medical_records_created_id|$createdRecordId"

  if ($createdRecordId) {
    $updRecord = Invoke-Api -Method "PUT" -Path "/api/medical-records/$createdRecordId" -Token $token -Body @{ doctorId = $createdDoctorId; recordDate = (Get-Date).ToString("o"); diagnosis = "Flu Updated"; treatmentPlan = "Rest and meds"; notes = "Updated" }
    "medical_records_update|$($updRecord.Status)"
  }
}
