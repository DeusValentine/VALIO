<img width="1280" height="640" alt="VALIO" src="https://github.com/user-attachments/assets/ca324913-da24-482e-834a-bed739119da8" />

VALIO. — ABAP Code Review AI Tool 

Original Authors:
- Valentine Liolia :suspect:
- Ihar Kantsevich 💀

An open-source SAP ABAP Tool that performs automatic code reviews using AI. 
Connect it to any SAP officially trusted reasoning LLM you have access to and get instant, structured feedback on your ABAP code.

## 🔭 What is it?

This tool automates ABAP code reviews. The main idea is to help development teams find weak and questionable places in the code before the transport release process. You can use it as an additional step in your workflow or as a self-review tool before showing the code to colleagues. Fix the main problems before they reach someone else and minimise the time spent on re-review cycles.

The quality of results depends on the API you connect and the prompts you use.

## 👉 Supported object types

Currently the tool supports ABAP classes only. Support for function modules and reports may come later.

## ⚡Getting started

### Prerequisites

You need access to any reasoning LLM API SAP officially allows to use (SAP Joule, OpenAI, Anthropic, Azure OpenAI, a local model, or anything else that accepts and returns text).

The program was developed on SAP_ABA 824. 
It should work on older versions as well, but we have not tested this yet. 
If you are running an older release and willing to give it a try, we would appreciate your feedback.

### Installation

The program was intentionally designed without an abapGit dependency. 
This keeps the installation simple and makes the project available for as many ABAP teams as possible. 
Copy and paste the program code into local objects in your system and you are ready to go.

### Configuration

There is one method you need to implement (class lcl_ai_helper method execute_prompt). The location is clearly marked in the code. Your implementation should call any reasoning LLM in the following format: input is a single string, output is a single string. That is all you need to start.

## 📄 How to use it

### Selecting objects for review

You can select review objects in two ways: by transport IDs or by object names.

For transport-based selection the screen provides transport ID and user name fields. You can enter specific transport IDs or a user name to retrieve their transports.

<img width="550" height="229" alt="изображение" src="https://github.com/user-attachments/assets/dffa887a-f245-4cd7-baf7-d70f59b2b44a" />


There is also a "Process only my transport requests" checkbox. When checked, transport IDs and user name fields are ignored and the program returns results only for active requests where you are involved. Note that in this case you will get objects from all persons in the request unless you also check "Get only my objects", which narrows the scope to objects from your tasks only.

### Review modes

Two review modes are available:

Quick mode processes entire objects at once. The context window stays large, so results may be less precise for complex objects.

Detailed mode combines full-object processing with a method-by-method review. For example, when reviewing a class it will process each method individually, keeping the context window as small as possible. Results are more precise and accurate, but it takes more tokens and time.

### Custom prompts

You can specify your own prompt by clicking the prompt edit button. Prompts can be saved as variant options, so you do not have to maintain them every time you enter the report.

<img width="1919" height="1079" alt="Screenshot 2026-05-14 121110" src="https://github.com/user-attachments/assets/f2ef1f2c-fce3-4cdb-b77c-fdb7417d7d30" />

This is useful when you want to focus on specific aspects of your code. For example, you can create a prompt that checks for performance issues, another one that evaluates SOLID principles compliance, and so on. Build multiple review scenarios according to your needs.

### Output options

The program supports three output formats: ALV grid, plain text, and Excel.

<img width="1919" height="1079" alt="Screenshot 2026-05-14 120745" src="https://github.com/user-attachments/assets/21da51a4-b67d-471c-967b-b38aaec87c56" />

Excel files can be saved directly to your PC or to a server path. If you choose server export, you need to specify the destination path on the selection screen. Server export is particularly helpful when running the program in the background for a large number of objects.

## 🌱 Contributing

Contributions are welcome. Feel free to open issues or submit pull requests.
