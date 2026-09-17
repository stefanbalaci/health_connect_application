# HealthConnect

HealthConnect is a full-stack mobile application developed as my bachelor's thesis at the Faculty of Automation and Computers, Politehnica University of Timișoara.

The project focuses on a practical problem: information related to appointments, prescriptions, medication schedules and medical reports is often spread across different places. HealthConnect brings these flows into one mobile application with separate experiences for patients and doctors.

## What the application does

### Patient
- Register and sign in securely
- Browse doctors and create medical appointments
- View upcoming and past appointments
- Follow prescribed medication and local reminders
- Track medication intake
- Upload and view medical reports

### Doctor
- Manage appointment requests and schedule
- View patients and their medical information
- Create digital prescriptions
- Add medication instructions and reminder times
- Review uploaded reports
- Export patient information as a PDF record

## Architecture

The application uses a client-server architecture:

- **Mobile client:** Flutter / Dart
- **Backend:** Java 17 / Spring Boot REST API
- **Database:** MariaDB
- **Security:** Spring Security 6, JWT and BCrypt
- **Persistence:** JPA / Hibernate
- **Networking:** Dio
- **Mapping / boilerplate:** MapStruct and Lombok
- **PDF generation:** PDFBox

The backend follows a Controller - Service - Repository structure and uses DTOs between the API and application layers.

## Main data model

The system is built around seven main JPA entities:

- User
- DoctorProfile
- PatientProfile
- Appointment
- Prescription
- PrescriptionItem
- VerificationCode

## Testing

REST endpoints were tested with Postman for both successful and error scenarios. Complete application flows were also validated on an Android emulator, including authentication and expired-token behaviour.

## Repositories

- Mobile application: https://github.com/stefanbalaci/health_connect_application
- Backend API: https://github.com/stefanbalaci/health_connect_backend

## Project scope

HealthConnect is designed as a digital tool for organization and doctor-patient communication. It does not provide automated medical diagnosis and is not intended to replace a medical professional.

## Future directions

Possible next steps include refresh tokens, Firebase Cloud Messaging push notifications, video teleconsultation and Docker-based deployment. The project is also the starting point for my proposed master's research direction, where I plan to explore distributed services, wearable-device data and more advanced healthcare platform architecture.
