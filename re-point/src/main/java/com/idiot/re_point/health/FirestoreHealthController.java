package com.idiot.re_point.health;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class FirestoreHealthController {

    private final Firestore firestore;

    // GET /health/firestore
    @GetMapping("/health/firestore")
    public ResponseEntity<Map<String, Object>> checkFirestore() throws Exception {
        // 1) users 컬렉션에서 문서 1개만 읽어보기 (존재 안 해도 예외는 아님)
        List<QueryDocumentSnapshot> docs =
                firestore.collection("users").limit(6).get().get().getDocuments();

        Map<String, Object> body = new HashMap<>();
        body.put("status", "OK");
        body.put("sampleCount", docs.size()); // 읽은 문서 수 (0 또는 1)
        return ResponseEntity.ok(body);
    }
}