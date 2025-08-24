package com.idiot.re_point.user.service;

import com.google.api.core.ApiFuture;
import com.google.cloud.Timestamp;
import com.google.cloud.firestore.*;
import com.idiot.re_point.user.dto.UpdateUserRequest;
import com.idiot.re_point.user.model.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
@RequiredArgsConstructor
public class UserService {

    private final Firestore firestore;

    private CollectionReference usersCol() {
        // 최상위 users 컬렉션
        return firestore.collection("users");
    }

    public User getByUid(String uid) throws ExecutionException, InterruptedException {
        DocumentSnapshot snap = usersCol().document(uid).get().get();
        if (!snap.exists()) return null;
        Map<String, Object> data = snap.getData();
        if (data == null) return null;

        // fromMap 이 created_at / updated_at 의 Timestamp/String 모두 처리
        // (혹시 과거에 camelCase 로 들어간 값이 있다면 보조 처리)
        if (!data.containsKey("created_at") && data.containsKey("createdAt")) {
            data.put("created_at", data.get("createdAt"));
        }
        if (!data.containsKey("updated_at") && data.containsKey("updatedAt")) {
            data.put("updated_at", data.get("updatedAt"));
        }

        return User.fromMap(uid, data);
    }

    public void upsert(String uid, User base) throws ExecutionException, InterruptedException {
        DocumentReference doc = usersCol().document(uid);
        DocumentSnapshot cur = doc.get().get();

        // created_at 유지 (camelCase 로 과거에 들어간 경우까지 고려)
        Object ca = cur.exists() ? (cur.get("created_at") != null ? cur.get("created_at") : cur.get("createdAt")) : null;
        if (ca instanceof Timestamp ts) {
            base.setCreatedAt(ts.toDate().toInstant());
        } else if (ca instanceof String s) {
            try { base.setCreatedAt(Instant.parse(s)); } catch (Exception ignored) { base.setCreatedAt(Instant.now()); }
        } else if (base.getCreatedAt() == null) {
            base.setCreatedAt(Instant.now());
        }

        base.setUpdatedAt(Instant.now());

        // toMap() 이 created_at / updated_at 을 Timestamp 로 저장
        doc.set(base.toMap(), SetOptions.merge()).get();
    }

    /** 주소(지역 문자열)만 간단 업데이트 */
    public void updateRegion(String uid, String province, String city, String district, String address)
            throws ExecutionException, InterruptedException {
        DocumentReference doc = firestore.collection("users").document(uid);

        DocumentSnapshot snap = doc.get().get();
        if (snap.exists()) {
            Map<String, Object> updateMap = new HashMap<>();
            updateMap.put("region_province", province);
            updateMap.put("region_city", city);
            updateMap.put("region_district", district);
            updateMap.put("address", address);
            updateMap.put("updated_at", Instant.now());

            doc.update(updateMap).get();
        } else {
            throw new RuntimeException("User not found: " + uid);
        }
    }

    public void deleteUserAndRelated(String uid) throws ExecutionException, InterruptedException {
        // 1) users/{uid} 삭제
        DocumentReference userDoc = firestore.collection("users").document(uid);
        userDoc.delete().get();

        // 2) 연관 데이터 삭제 (스키마에 맞게 필요 컬렉션 추가)
        deleteByQuery("points", "user_id", uid);     // 포인트 이력
        deleteByQuery("exchanges", "user_id", uid);  // 교환 이력 (컬렉션명이 다르면 수정)
        // deleteByQuery("giftcards", "owner_uid", uid); // 소유권 필드가 있다면 예시
    }

    private void deleteByQuery(String collection, String field, String uid)
            throws ExecutionException, InterruptedException {

        CollectionReference col = firestore.collection(collection);
        Query q = col.whereEqualTo(field, uid).limit(500);

        while (true) {
            QuerySnapshot snap = q.get().get();
            List<QueryDocumentSnapshot> docs = snap.getDocuments();
            if (docs.isEmpty()) break;

            WriteBatch batch = firestore.batch();
            for (QueryDocumentSnapshot d : docs) {
                batch.delete(d.getReference());
            }
            batch.commit().get();

            // 페이지네이션 (커서)
            DocumentSnapshot last = docs.get(docs.size() - 1);
            q = col.whereEqualTo(field, uid)
                    .startAfter(last)
                    .limit(500);
        }
    }

    /** 부분 업데이트 (null 인 필드는 무시) */
    public User updateUser(String uid, UpdateUserRequest req) throws ExecutionException, InterruptedException {
        var doc = usersCol().document(uid);
        var cur = doc.get().get();



        Map<String, Object> patch = new HashMap<>();
        if (!cur.exists()) {
            patch.put("point", req.getPoint() != null ? req.getPoint() : 0L);
            patch.put("created_at", Timestamp.now());
        }


        if (req.getName() != null)          patch.put("name", req.getName());
        if (req.getEmail() != null)         patch.put("email", req.getEmail());
        if (req.getProfileUrl() != null)    patch.put("profile_url", req.getProfileUrl());
        if (req.getAddress() != null)       patch.put("address", req.getAddress());
        if (req.getLoginProvider() != null) patch.put("login_provider", req.getLoginProvider());

        // 최초 생성 시 created_at 보정
        if (!cur.exists() || cur.get("created_at") == null) {
            patch.put("created_at", Timestamp.now());
        }
        patch.put("updated_at", Timestamp.now());

        doc.set(patch, SetOptions.merge()).get();
        return getByUid(uid);
    }

}