#include <optional>

#include <wx/wx.h>
#include <wx/listctrl.h>

extern "C" {

    static std::optional<wxDialog*> logViewer;
    static std::optional<wxListCtrl*> logViewerList;

    int initCXXNativeUtils() {
        return 0;
    }

    int initLogViewer(NSWindow* window) {
        // convert NSWindow to wxWindow
        auto logViewerWindow = new wxDialog(nullptr, wxID_ANY, "Log Viewer", wxDefaultPosition, wxSize(800, 600), wxCLOSE_BOX | wxRESIZE_BORDER);
        logViewerWindow->Bind(wxEVT_SIZING, [](wxSizeEvent& event) {
            if (auto logViewerWindow = logViewer.value()) {
                logViewerWindow->Freeze();
                if (logViewerList.has_value())
                    logViewerList.value()->SetColumnWidth(2, event.GetSize().GetWidth() - 200);
                logViewerWindow->Thaw();
            }
        });

        auto list = new wxListCtrl(logViewerWindow, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT);
        list->InsertColumn(0, "Time", wxLIST_FORMAT_LEFT, 100);
        list->InsertColumn(1, "Level");
        list->InsertColumn(2, "Message", wxLIST_FORMAT_LEFT, logViewerWindow->GetSize().GetWidth() - 200);

        auto sizer = new wxBoxSizer(wxVERTICAL);
        sizer->Add(list, 1, wxEXPAND);
        logViewerWindow->SetSizer(sizer);

        logViewer = logViewerWindow;
        logViewerList = list;
        return EXIT_SUCCESS;
    }

    void addLogEntry(const char* time, const char* level, const char* message) {
        if (logViewer.has_value() && logViewerList.has_value()) {
            auto list = logViewerList.value();
            list->InsertItem(list->GetItemCount(), time);
            list->SetItem(list->GetItemCount() - 1, 1, level);
            list->SetItem(list->GetItemCount() - 1, 2, message);

            list->EnsureVisible(list->GetItemCount() - 1);
        }
    }

    void showLogViewer() {
        if (logViewer.has_value()) {
            auto logViewerWindow = logViewer.value();
            logViewerWindow->Center();
            logViewerWindow->Show(true);
        }
    }

    void terminateCXXNativeUtils() {
        if (logViewer.has_value()) {
            logViewer.value()->Destroy();
            logViewer.reset();
        }
    }

}