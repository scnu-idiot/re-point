package com.idiot.re_point.point.service;

import com.google.api.core.ApiFuture;
import com.google.cloud.Timestamp;
import com.google.cloud.firestore.*;
import com.idiot.re_point.point.dto.PointEarnEventRequest;
import com.idiot.re_point.point.dto.PointEarnInviteRequest;
import com.idiot.re_point.point.dto.PointEarnReceiptRequest;
import com.idiot.re_point.point.dto.PointHistoryDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ExecutionException;

import static com.google.cloud.firestore.FieldValue.increment;

@Service
@RequiredArgsConstructor
public class PointService {

    private final Firestore firestore;

    private CollectionReference users()  { return firestore.collection("users"); }
    private CollectionReference points() { return firestore.collection("points"); }

    /** 공통 저장 로직: points 문서 생성 + users.point 증가 */
    private long addPoint(String uid, long value, Map<String, Object> extra, String text, String type)
            throws ExecutionException, InterruptedException {

        // 1) points 컬렉션(최상위)에 문서 생성
        DocumentReference doc = points().document(); // auto id
        Map<String, Object> data = new HashMap<>();
        data.put("uid", uid);
        data.put("point_text", text);      // 예: "영수증 인증 적립"
        data.put("point_type", type);      // receipt | invite | event
        data.put("point_value", value);    // +값
        data.put("created_at", Timestamp.now());

        if (extra != null) data.putAll(extra);
        doc.set(data).get();

        // 2) users/{uid}.point 증가(존재 없으면 0에서 증가)
        DocumentReference userDoc = users().document(uid);
        userDoc.set(Collections.singletonMap("point", increment(value)), SetOptions.merge()).get();

        // 3) 최신 잔액 읽어서 반환
        Number n = 0;
        DocumentSnapshot snap = userDoc.get().get();
        if (snap.exists() && snap.get("point") != null) {
            n = (Number) snap.get("point");
        }
        return n.longValue();
    }

    // ===== earn variants =====

    public long earnByReceipt(String uid, PointEarnReceiptRequest req)
            throws ExecutionException, InterruptedException {
        long value = 100L; // 고정
        Map<String, Object> extra = new HashMap<>();
        extra.put("receipt_id",   req.getReceiptId());
        if (req.getDetail() != null) extra.put("receipt_detail", req.getDetail());
        if (req.getTitle()  != null) extra.put("title", req.getTitle());
        return addPoint(uid, value, extra, "영수증 인증 적립", "receipt");
    }

    public long earnByInvite(String uid, PointEarnInviteRequest req)
            throws ExecutionException, InterruptedException {
        long value = 500L; // 고정
        Map<String, Object> extra = new HashMap<>();
        extra.put("invite_id",    req.getInviteId());
        if (req.getDetail() != null) extra.put("invite_detail", req.getDetail());
        if (req.getTitle()  != null) extra.put("title", req.getTitle());
        return addPoint(uid, value, extra, "친구 초대 적립", "invite");
    }

    public long earnByEvent(String uid, PointEarnEventRequest req)
            throws ExecutionException, InterruptedException {
        long value = (req.getAmount() == null ? 0L : req.getAmount());
        Map<String, Object> extra = new HashMap<>();
        extra.put("event_id",     req.getEventId());
        if (req.getDetail() != null) extra.put("event_detail", req.getDetail());
        if (req.getTitle()  != null) extra.put("title", req.getTitle());
        return addPoint(uid, value, extra, "이벤트 참여 적립", "event");
    }

    // ===== history =====
    public List<PointHistoryDto> history(String uid, String source, int limit, Instant before)
            throws ExecutionException, InterruptedException {

        Query q = points().whereEqualTo("uid", uid)
                .orderBy("created_at", Query.Direction.DESCENDING);

        if (!"all".equalsIgnoreCase(source)) {
            // source: receipt | invite | event
            q = q.whereEqualTo("point_type", source.toLowerCase(Locale.ROOT));
        }
        if (limit <= 0 || limit > 100) limit = 20;

        if (before != null) {
            q = q.whereLessThan("created_at",
                    Timestamp.ofTimeSecondsAndNanos(before.getEpochSecond(), before.getNano()));
        }
        q = q.limit(limit);

        List<QueryDocumentSnapshot> docs = q.get().get().getDocuments();
        List<PointHistoryDto> out = new ArrayList<>(docs.size());

        for (QueryDocumentSnapshot d : docs) {
            Map<String, Object> m = d.getData();
            PointHistoryDto.PointHistoryDtoBuilder b = PointHistoryDto.builder()
                    .id(d.getId())
                    .uid((String) m.getOrDefault("uid", ""))
                    .type((String) m.getOrDefault("point_type", ""))
                    .title((String) m.getOrDefault("title", ""))
                    .detail((String) Optional.ofNullable(m.get("receipt_detail"))
                            .orElse(Optional.ofNullable(m.get("invite_detail"))
                                    .orElse((String) m.getOrDefault("event_detail", ""))))
                    .amount(((Number) m.getOrDefault("point_value", 0)).longValue());

            Object ts = m.get("created_at");
            if (ts instanceof Timestamp t) b.createdAt(t.toDate().toInstant());

            out.add(b.build());
        }
        return out;
    }
}