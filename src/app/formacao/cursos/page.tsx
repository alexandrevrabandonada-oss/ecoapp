export default function Page({ params }: any) {
  return (
    <main style={{ padding: 24 }}>
      <h1 style={{ marginTop: 0 }}></h1>
      <p></p>
      <pre style={{ opacity: 0.8 }}>params: {JSON.stringify(params, null, 2)}</pre>
    </main>
  );
}
