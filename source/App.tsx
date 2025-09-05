import React, { useState } from 'react';
import { Header } from './components/Layout/Header';
import { Sidebar } from './components/Layout/Sidebar';
import { Dashboard } from './components/Dashboard/Dashboard';
import { CasesList } from './components/Cases/CasesList';
import { NewCaseForm } from './components/Cases/NewCaseForm';
import { CaseDetails } from './components/Cases/CaseDetails';
import { ThreadsList } from './components/Discussions/ThreadsList';
import { ThreadView } from './components/Discussions/ThreadView';
import { NewThreadForm } from './components/Discussions/NewThreadForm';
import { DocumentsList } from './components/Documents/DocumentsList';
import { DocumentUpload } from './components/Documents/DocumentUpload';
import { DocumentViewer } from './components/Documents/DocumentViewer';
import { CirclesList } from './components/Circles/CirclesList';
import { CircleDetails } from './components/Circles/CircleDetails';
import { CollaborationManager } from './components/Circles/CollaborationManager';
import { NewCircleForm } from './components/Circles/NewCircleForm';
import { ToastContainer } from './components/Notifications/NotificationToast';
import { useNotifications } from './hooks/useNotifications';
import { AuditLog } from './components/Audit/AuditLog';
import { ReportsDashboard } from './components/Reports/ReportsDashboard';

function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [selectedCaseId, setSelectedCaseId] = useState<string | null>(null);
  const [selectedThreadId, setSelectedThreadId] = useState<string | null>(null);
  const [selectedDocumentId, setSelectedDocumentId] = useState<string | null>(null);
  const [selectedCircleId, setSelectedCircleId] = useState<string | null>(null);
  const { toasts, removeToast, showSuccess, showError, showInfo } = useNotifications();
  
  // Mock profile state that can be updated
  const [mockProfile, setMockProfile] = useState({
    id: 'mock-user-id',
    full_name: 'أحمد محمد القاضي',
    role: 'judge' as const,
    circle_id: 'mock-circle-id',
    employee_id: 'EMP001',
    created_at: new Date().toISOString(),
    judicial_circle: {
      id: 'mock-circle-id',
      name: 'الدائرة الجزائية الأولى',
      description: 'دائرة متخصصة في القضايا الجزائية',
      created_at: new Date().toISOString()
    }
  });

  const updateProfile = (updates: Partial<typeof mockProfile>) => {
    setMockProfile(prev => ({ ...prev, ...updates }));
    showSuccess('تم حفظ التغييرات', 'تم تحديث الملف الشخصي بنجاح');
  };

  const handleCaseSelect = (caseId: string) => {
    setSelectedCaseId(caseId);
    setActiveTab('case-details');
  };

  const handleNewCase = () => {
    setActiveTab('new-case');
  };

  const handleCaseCreated = (caseId: string) => {
    setSelectedCaseId(caseId);
    setActiveTab('case-details');
    showSuccess('تم إنشاء القضية', 'تم إنشاء القضية الجديدة بنجاح');
  };

  const handleBackToCases = () => {
    setSelectedCaseId(null);
    setActiveTab('cases');
  };

  const handleThreadSelect = (threadId: string) => {
    setSelectedThreadId(threadId);
    setActiveTab('thread-view');
  };

  const handleNewThread = () => {
    setActiveTab('new-thread');
  };

  const handleThreadCreated = (threadId: string) => {
    setSelectedThreadId(threadId);
    setActiveTab('thread-view');
    showSuccess('تم إنشاء المناقشة', 'تم إنشاء المناقشة الجديدة بنجاح');
  };

  const handleBackToThreads = () => {
    setSelectedThreadId(null);
    setActiveTab('threads');
  };

  const handleDocumentSelect = (documentId: string) => {
    setSelectedDocumentId(documentId);
    setActiveTab('document-viewer');
  };

  const handleUploadDocument = () => {
    setActiveTab('document-upload');
  };

  const handleDocumentUploaded = (documentId: string) => {
    setSelectedDocumentId(documentId);
    setActiveTab('document-viewer');
    showSuccess('تم رفع المستند', 'تم رفع المستند ومعالجته بتقنية OCR بنجاح');
  };

  const handleBackToDocuments = () => {
    setSelectedDocumentId(null);
    setActiveTab('documents');
  };

  const handleCircleSelect = (circleId: string) => {
    setSelectedCircleId(circleId);
    setActiveTab('circle-details');
  };

  const handleNewCircle = () => {
    setActiveTab('new-circle');
  };

  const handleCircleCreated = (circleId: string) => {
    setSelectedCircleId(circleId);
    setActiveTab('circle-details');
    showSuccess('تم إنشاء الدائرة', 'تم إنشاء الدائرة القضائية الجديدة بنجاح');
  };

  const handleBackToCircles = () => {
    setSelectedCircleId(null);
    setActiveTab('circles');
  };

  const handleManageCollaboration = (circleId: string) => {
    setSelectedCircleId(circleId);
    setActiveTab('collaboration-manager');
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <Dashboard mockProfile={mockProfile} />;
      case 'cases':
        return <CasesList onCaseSelect={handleCaseSelect} onNewCase={handleNewCase} />;
      case 'new-case':
        return <NewCaseForm onBack={handleBackToCases} onCaseCreated={handleCaseCreated} />;
      case 'case-details':
        return selectedCaseId ? (
          <CaseDetails caseId={selectedCaseId} onBack={handleBackToCases} />
        ) : (
          <CasesList onCaseSelect={handleCaseSelect} onNewCase={handleNewCase} />
        );
      case 'threads':
        return <ThreadsList onThreadSelect={handleThreadSelect} onNewThread={handleNewThread} />;
      case 'new-thread':
        return <NewThreadForm onBack={handleBackToThreads} onThreadCreated={handleThreadCreated} />;
      case 'thread-view':
        return selectedThreadId ? (
          <ThreadView threadId={selectedThreadId} onBack={handleBackToThreads} />
        ) : (
          <ThreadsList onThreadSelect={handleThreadSelect} onNewThread={handleNewThread} />
        );
      case 'documents':
        return <DocumentsList onDocumentSelect={handleDocumentSelect} onUploadDocument={handleUploadDocument} />;
      case 'document-upload':
        return <DocumentUpload onBack={handleBackToDocuments} onUploadComplete={handleDocumentUploaded} />;
      case 'document-viewer':
        return selectedDocumentId ? (
          <DocumentViewer documentId={selectedDocumentId} onBack={handleBackToDocuments} />
        ) : (
          <DocumentsList onDocumentSelect={handleDocumentSelect} onUploadDocument={handleUploadDocument} />
        );
      case 'circles':
        return <CirclesList onCircleSelect={handleCircleSelect} onNewCircle={handleNewCircle} onManageCollaboration={handleManageCollaboration} />;
      case 'new-circle':
        return <NewCircleForm onBack={handleBackToCircles} onCircleCreated={handleCircleCreated} />;
      case 'circle-details':
        return selectedCircleId ? (
          <CircleDetails 
            circleId={selectedCircleId} 
            onBack={handleBackToCircles}
            onManageCollaboration={() => handleManageCollaboration(selectedCircleId)}
          />
        ) : (
          <CirclesList onCircleSelect={handleCircleSelect} onNewCircle={handleNewCircle} onManageCollaboration={handleManageCollaboration} />
        );
      case 'collaboration-manager':
        return selectedCircleId ? (
          <CollaborationManager circleId={selectedCircleId} onBack={handleBackToCircles} />
        ) : (
          <CirclesList onCircleSelect={handleCircleSelect} onNewCircle={handleNewCircle} onManageCollaboration={handleManageCollaboration} />
        );
      case 'audit':
        return <AuditLog />;
      case 'reports':
        return <ReportsDashboard />;
      default:
        return <Dashboard mockProfile={mockProfile} />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50" dir="rtl">
      <Header mockProfile={mockProfile} onProfileUpdate={updateProfile} />
      <div className="flex">
        <Sidebar activeTab={activeTab} onTabChange={setActiveTab} mockProfile={mockProfile} />
        <main className="flex-1 p-6">
          {renderContent()}
        </main>
      </div>
      
      {/* Toast Notifications */}
      <ToastContainer notifications={toasts} onClose={removeToast} />
    </div>
  );
}

export default App;